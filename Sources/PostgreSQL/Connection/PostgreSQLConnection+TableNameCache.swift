extension PostgreSQLConnection {
    /// Caches table OID to string name associations.
    public struct TableNameCache {
        /// Stores table names. [OID: Name]
        private let tableNames: [UInt32: String]
        
        /// Fetches the table name for a given table OID. Returns `nil` if no table with that OID is known.
        ///
        /// - parameters:
        ///     - oid: Table OID.
        /// - returns: Table name.
        public func tableName(oid: UInt32) -> String? {
            return tableNames[oid]
        }
        
        /// Fetches the table OID for a given table name. Returns `nil` if no table with that name is known.
        ///
        /// - parameters:
        ///     - name: Table name.
        /// - returns: Table OID.
        public func tableOID(name: String) -> UInt32? {
            for (key, val) in tableNames {
                if val == name {
                    return key
                }
            }
            return nil
        }
        
        /// Creates a new cache.
        init(_ tableNames: [UInt32: String]) {
            self.tableNames = tableNames
        }
    }
    
    /// Fetches a struct that can convert table OIDs to table names.
    ///
    ///     SELECT oid, relname FROM pg_class
    ///
    /// The table names will be cached on the connection after fetching.
    public func tableNames() -> Future<TableNameCache> {
        if let existing = tableNameCache {
            return future(existing)
        } else {
            struct PGClass: PostgreSQLTable {
                static let postgreSQLTable = "pg_class"
                var oid: UInt32
                var relname: String
            }
            return select().keys("oid", "relname").from(PGClass.self).run(decoding: PGClass.self).map { rows in
                var cache: [UInt32: String] = [:]
                for row in rows {
                    cache[row.oid] = row.relname
                }
                let new = TableNameCache(cache)
                self.tableNameCache = new
                return new
            }
        }
    }
}
