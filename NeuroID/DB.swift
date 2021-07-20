import Foundation

class DB {
    struct DBResult {
        var screen: String
        var base64Strings: [String]
    }
    private init() {
        createTable()
    }
    static var shared = DB()
    private lazy var db = openDatabase()
    private func openDatabase(fileName: String = "db.sqlite") -> OpaquePointer? {
        var db: OpaquePointer?
        let defaultDbPath = try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(fileName).relativePath
        guard let dbPath = defaultDbPath else {
            return nil
        }

        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            let password = generatePassword()
            var rc = sqlite3_key(db, password, Int32(password.utf8CString.count))
            if rc != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db))
                niprint("Error setting key: \(errmsg)")
            }

            var stmt: OpaquePointer?
            rc = sqlite3_prepare(db, "PRAGMA cipher_version;", -1, &stmt, nil)
            if rc != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db))
                niprint("Error preparing SQL: \(errmsg)")
            }
            rc = sqlite3_step(stmt)
            if rc != SQLITE_ROW {
                let errmsg = String(cString: sqlite3_errmsg(db))
                niprint("Error retrieiving cipher_version: \(errmsg)")
            }
            sqlite3_finalize(stmt)

            return db
        } else {
            niprint("Unable to open database.")
        }
        return db
    }

    private func generatePassword() -> String {
        if let password = KeychainService.loadPassword() {
            return password
        } else {
            let password = UUID().uuidString
            DispatchQueue.global().async {
                KeychainService.savePassword(data: password)
            }
            return password
        }
    }

    private func createTable() {
        let queryString =
            """
CREATE TABLE IF NOT EXISTS Events(
Screen TEXT NOT NULL,
Base64 TEXT NOT NULL,
Status TEXT NOT NULL);
"""
        var statement: OpaquePointer?
        if prepare(queryString: queryString, statement: &statement) {
            execute(statement)
        }
        endExecution(statement)
    }

    func insert(screen: String, base64String: String) {
        DispatchQueue.global(qos: .background).async {
            let queryString = "INSERT INTO Events (Screen, Base64, Status) VALUES ('\(screen)', '\(base64String)', 'pending');"
            var statement: OpaquePointer?

            if self.prepare(queryString: queryString, statement: &statement) {
                self.execute(statement)
                self.endExecution(statement)
            }
        }
    }

    func getAll() -> DBResult {
        let results = queryAll()
        updateSending(base64Strings: results.base64Strings)
        return results
    }

    private func queryAll() -> DBResult {
        let queryString = "SELECT * FROM Events WHERE Status == 'pending';"
        var statement: OpaquePointer?

        var base64Strings = [String]()
        var screen: String?
        if prepare(queryString: queryString, statement: &statement) {
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let screenRaw = sqlite3_column_text(statement, 0),
                      let rawBase64 = sqlite3_column_text(statement, 1) else {
                    continue
                }
                screen = String(cString: screenRaw)
                let base64 = String(cString: rawBase64)
                base64Strings.append(base64)
            }
        }

        endExecution(statement)
        return DBResult(screen: screen ?? UUID().uuidString, base64Strings: base64Strings)
    }

    func updateSending(base64Strings: [String]) {
        var statement: OpaquePointer?

        for string in base64Strings {
            let queryString = "UPDATE Events SET Status = 'sending' WHERE Base64 = '\(string)';"
            if prepare(queryString: queryString, statement: &statement) {
                execute(statement)
            }
        }
        endExecution(statement)
    }

    func deleteSent() {
        DispatchQueue.global(qos: .background).async {
            let queryString = "DELETE FROM Events WHERE Status = 'sending';"
            var statement: OpaquePointer?
            if self.prepare(queryString: queryString, statement: &statement) {
                self.execute(statement)
            }
            self.endExecution(statement)
        }
    }

    @discardableResult
    private func prepare(queryString: String, statement: inout OpaquePointer?) -> Bool {
        if sqlite3_prepare(db, queryString, -1, &statement, nil) == SQLITE_OK {
            return true
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            niprint("queryString", queryString, "was not prepared", "error", errorMessage)
            return false
        }
    }

    @discardableResult
    private func execute(_ statement: OpaquePointer?) -> Bool {
        if sqlite3_step(statement) == SQLITE_DONE {
            return true
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            niprint("Could execute", errorMessage)
            return false
        }
    }

    private func endExecution(_ statement: OpaquePointer?) {
        sqlite3_finalize(statement)
    }
}

extension DB {
    func setupTest(dbName: String) {
        db = openDatabase(fileName: dbName)
        createTable()
    }

    func cleanUpForTest(dbName: String) {
        let queryString = "DELETE FROM Events;"
        var statement: OpaquePointer?
        if prepare(queryString: queryString, statement: &statement) {
            execute(statement)
        }
        endExecution(statement)

        let defaultDbPath = try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(dbName).relativePath
        guard let dbPath = defaultDbPath else {
            return
        }
        let url = URL(fileURLWithPath: dbPath)
        try? FileManager.default.removeItem(at: url)
    }
}

let kSecClassValue = NSString(format: kSecClass)
let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
let kSecValueDataValue = NSString(format: kSecValueData)
let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
let kSecAttrServiceValue = NSString(format: kSecAttrService)
let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
let kSecReturnDataValue = NSString(format: kSecReturnData)
let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)

private class KeychainService: NSObject {
    static let service = "NeuroId"
    static let account = "ios"
    class func updatePassword(data: String) {
        guard let dataFromString: Data = data.data(using: String.Encoding.utf8, allowLossyConversion: false) else { return }

        let keychainQuery = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue])

        let status = SecItemUpdate(keychainQuery as CFDictionary, [kSecValueDataValue: dataFromString] as CFDictionary)

        if status != errSecSuccess {
            if #available(iOS 11.3, *) {
                if let err = SecCopyErrorMessageString(status, nil) {
                    niprint("Read failed: \(err)")
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }

    class func removePassword() {
        let keychainQuery = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, true], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue])

        let status = SecItemDelete(keychainQuery as CFDictionary)
        if #available(iOS 11.3, *) {
            if (status != errSecSuccess), let err = SecCopyErrorMessageString(status, nil) {
                niprint("Remove failed: \(err)")
            }
        } else {
            // Fallback on earlier versions
        }

    }

    class func savePassword(data: String) {
        guard let dataFromString = data.data(using: String.Encoding.utf8, allowLossyConversion: false) else { return }

        let keychainQuery = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, dataFromString], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecValueDataValue])

        let status = SecItemAdd(keychainQuery as CFDictionary, nil)

        if #available(iOS 11.3, *) {
            if (status != errSecSuccess), let err = SecCopyErrorMessageString(status, nil) {
                niprint("Write failed: \(err)")
            }
        } else {
            // Fallback on earlier versions
        }
    }

    class func loadPassword() -> String? {
        let keychainQuery = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, true, kSecMatchLimitOneValue], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue])

        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        var contentsOfKeychain: String?

        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                contentsOfKeychain = String(data: retrievedData, encoding: String.Encoding.utf8)
            }
        } else {
            niprint("Nothing was retrieved from the keychain. Status code \(status)")
        }

        return contentsOfKeychain
    }
}
