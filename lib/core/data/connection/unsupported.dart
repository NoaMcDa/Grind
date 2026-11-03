import 'package:drift/drift.dart';

/// File name of the database (native) / database name (web).
const databaseName = 'grind';

/// Platform connection; see `connection.dart`.
QueryExecutor openConnection({String name = databaseName}) =>
    throw UnsupportedError('No database connection for this platform.');
