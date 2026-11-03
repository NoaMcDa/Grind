import EventKit
import Flutter
import Foundation

/// Grind's bridge to EventKit. Dart side: lib/features/calendar/apple/.
/// Decision and manual test plan: docs/adr/0006-apple-calendar.md.
///
/// Method channel `grind/apple_calendar`:
///   authorizationStatus, requestFullAccess, requestWriteOnlyAccess
///     -> String status: notDetermined | restricted | denied | fullAccess | writeOnly
///   listCalendars -> [{id, title, allowsContentModifications, isPrimary}]
///   fetchEvents {calendarIds, fromMs, toMs} -> [{eventIdentifier, calendarIdentifier,
///     title, startMs, endMs, isAllDay, isBusy, isRecurring, notes?, url?,
///     createdMs?, updatedMs?}]
///   createEvent {calendarId?, title, startMs, endMs, notes?, taskId?} -> eventIdentifier
///   updateEvent {eventId, title, startMs, endMs, notes?, taskId?} -> nil
///   deleteEvent {eventId} -> nil
/// Errors: FlutterError code `notFound`, `invalidArgs`, `eventKit`.
///
/// Event channel `grind/apple_calendar/changes` emits "onStoreChanged" on
/// every EKEventStoreChanged notification.
final class AppleCalendarPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private let store = EKEventStore()
  private var observer: NSObjectProtocol?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = AppleCalendarPlugin()
    let methods = FlutterMethodChannel(
      name: "grind/apple_calendar", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
    let changes = FlutterEventChannel(
      name: "grind/apple_calendar/changes", binaryMessenger: registrar.messenger())
    changes.setStreamHandler(instance)
  }

  // MARK: - Method calls

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "authorizationStatus":
      result(Self.statusString())
    case "requestFullAccess":
      requestFullAccess(result)
    case "requestWriteOnlyAccess":
      requestWriteOnlyAccess(result)
    case "listCalendars":
      result(listCalendars())
    case "fetchEvents":
      fetchEvents(args, result)
    case "createEvent":
      createEvent(args, result)
    case "updateEvent":
      updateEvent(args, result)
    case "deleteEvent":
      deleteEvent(args, result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Permission

  /// Raw values keep this compiling for the iOS 13 deployment target:
  /// 0 notDetermined, 1 restricted, 2 denied, 3 authorized/fullAccess
  /// (iOS 17 renamed it), 4 writeOnly (iOS 17+).
  private static func statusString() -> String {
    switch EKEventStore.authorizationStatus(for: .event).rawValue {
    case 0: return "notDetermined"
    case 1: return "restricted"
    case 2: return "denied"
    case 3: return "fullAccess"
    case 4: return "writeOnly"
    default: return "denied"
    }
  }

  private func requestFullAccess(_ result: @escaping FlutterResult) {
    let done: (Bool, Error?) -> Void = { [weak self] granted, _ in
      DispatchQueue.main.async {
        if granted { self?.store.reset() }
        result(Self.statusString())
      }
    }
    if #available(iOS 17.0, *) {
      store.requestFullAccessToEvents(completion: done)
    } else {
      store.requestAccess(to: .event, completion: done)
    }
  }

  private func requestWriteOnlyAccess(_ result: @escaping FlutterResult) {
    let done: (Bool, Error?) -> Void = { [weak self] granted, _ in
      DispatchQueue.main.async {
        if granted { self?.store.reset() }
        result(Self.statusString())
      }
    }
    if #available(iOS 17.0, *) {
      store.requestWriteOnlyAccessToEvents(completion: done)
    } else {
      // Before iOS 17 there is only one level: full access.
      store.requestAccess(to: .event, completion: done)
    }
  }

  // MARK: - Calendars

  private func listCalendars() -> [[String: Any]] {
    let defaultId = store.defaultCalendarForNewEvents?.calendarIdentifier
    return store.calendars(for: .event).map { calendar in
      [
        "id": calendar.calendarIdentifier,
        "title": calendar.title,
        "allowsContentModifications": calendar.allowsContentModifications,
        "isPrimary": calendar.calendarIdentifier == defaultId,
      ]
    }
  }

  // MARK: - Events

  private func fetchEvents(_ args: [String: Any], _ result: @escaping FlutterResult) {
    guard let ids = args["calendarIds"] as? [String],
      let from = Self.date(args["fromMs"]),
      let to = Self.date(args["toMs"])
    else {
      result(Self.invalidArgs("fetchEvents"))
      return
    }
    let calendars = store.calendars(for: .event).filter { ids.contains($0.calendarIdentifier) }
    // An empty list would mean "all calendars" to EventKit; Grind means none.
    if calendars.isEmpty || from >= to {
      result([[String: Any]]())
      return
    }
    let predicate = store.predicateForEvents(withStart: from, end: to, calendars: calendars)
    let events = store.events(matching: predicate).compactMap { event -> [String: Any]? in
      guard let id = event.eventIdentifier else { return nil }
      var map: [String: Any] = [
        "eventIdentifier": id,
        "calendarIdentifier": event.calendar?.calendarIdentifier ?? "",
        "title": event.title ?? "",
        "startMs": Self.ms(event.startDate),
        "endMs": Self.ms(event.endDate),
        "isAllDay": event.isAllDay,
        "isBusy": event.availability != .free,
        "isRecurring": event.hasRecurrenceRules,
      ]
      if let notes = event.notes { map["notes"] = notes }
      if let url = event.url { map["url"] = url.absoluteString }
      if let created = event.creationDate { map["createdMs"] = Self.ms(created) }
      if let updated = event.lastModifiedDate { map["updatedMs"] = Self.ms(updated) }
      return map
    }
    result(events)
  }

  private func createEvent(_ args: [String: Any], _ result: @escaping FlutterResult) {
    let calendarId = args["calendarId"] as? String
    let calendar =
      calendarId.flatMap { store.calendar(withIdentifier: $0) } ?? store.defaultCalendarForNewEvents
    guard let target = calendar else {
      result(FlutterError(code: "notFound", message: "No writable calendar", details: nil))
      return
    }
    let event = EKEvent(eventStore: store)
    event.calendar = target
    guard apply(args, to: event) else {
      result(Self.invalidArgs("createEvent"))
      return
    }
    save(event, result) { result(event.eventIdentifier) }
  }

  private func updateEvent(_ args: [String: Any], _ result: @escaping FlutterResult) {
    guard let id = args["eventId"] as? String else {
      result(Self.invalidArgs("updateEvent"))
      return
    }
    guard let event = store.event(withIdentifier: id) else {
      result(FlutterError(code: "notFound", message: "No event \(id)", details: nil))
      return
    }
    guard apply(args, to: event) else {
      result(Self.invalidArgs("updateEvent"))
      return
    }
    save(event, result) { result(nil) }
  }

  private func deleteEvent(_ args: [String: Any], _ result: @escaping FlutterResult) {
    guard let id = args["eventId"] as? String else {
      result(Self.invalidArgs("deleteEvent"))
      return
    }
    guard let event = store.event(withIdentifier: id) else {
      result(FlutterError(code: "notFound", message: "No event \(id)", details: nil))
      return
    }
    do {
      try store.remove(event, span: .thisEvent, commit: true)
      result(nil)
    } catch {
      result(FlutterError(code: "eventKit", message: error.localizedDescription, details: nil))
    }
  }

  /// Copies title, times, notes and the write-back marker onto [event].
  /// The marker is `grind://task/<taskId>` in the URL field; the Dart side
  /// also puts `grindTaskId:<taskId>` in the notes it sends.
  private func apply(_ args: [String: Any], to event: EKEvent) -> Bool {
    guard let title = args["title"] as? String,
      let start = Self.date(args["startMs"]),
      let end = Self.date(args["endMs"]),
      end > start
    else { return false }
    event.title = title
    event.startDate = start
    event.endDate = end
    event.isAllDay = false
    event.notes = args["notes"] as? String
    if let taskId = args["taskId"] as? String,
      let encoded = taskId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    {
      event.url = URL(string: "grind://task/\(encoded)")
    }
    return true
  }

  private func save(
    _ event: EKEvent, _ result: @escaping FlutterResult, then success: () -> Void
  ) {
    do {
      try store.save(event, span: .thisEvent, commit: true)
      success()
    } catch {
      result(FlutterError(code: "eventKit", message: error.localizedDescription, details: nil))
    }
  }

  // MARK: - Change stream

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    removeObserver()
    observer = NotificationCenter.default.addObserver(
      forName: .EKEventStoreChanged, object: store, queue: .main
    ) { _ in
      events("onStoreChanged")
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    removeObserver()
    return nil
  }

  private func removeObserver() {
    if let observer = observer {
      NotificationCenter.default.removeObserver(observer)
    }
    observer = nil
  }

  deinit { removeObserver() }

  // MARK: - Helpers

  private static func date(_ value: Any?) -> Date? {
    guard let number = value as? NSNumber else { return nil }
    return Date(timeIntervalSince1970: number.doubleValue / 1000)
  }

  private static func ms(_ date: Date) -> Int64 {
    Int64((date.timeIntervalSince1970 * 1000).rounded())
  }

  private static func invalidArgs(_ method: String) -> FlutterError {
    FlutterError(code: "invalidArgs", message: "Bad arguments for \(method)", details: nil)
  }
}
