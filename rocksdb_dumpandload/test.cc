#include <iostream>
#include <rocksdb/db.h>
#include <rocksdb/utilities/backup_engine.h>
#include <vector>
#include <cstdlib>

using namespace rocksdb;

int main() {

    // Parse command-line arguments
    std::string db_path = "/tmp/rocksdb_restore";

    // Open the RocksDB database to check for column families
    DB* db;
    Options options;
    options.create_if_missing = false;

    // List all column families in the database
    std::vector<std::string> column_family_names;
    Status s = DB::ListColumnFamilies(options, db_path, &column_family_names);

    if (!s.ok()) {
        std::cerr << "Error listing column families in RocksDB: " << s.ToString() << std::endl;
        return 1;
    }

    // Print all column families
    std::cout << "Column Families:" << std::endl;
    for (const auto& name : column_family_names) {
        std::cout << "- " << name << std::endl;
    }

    // Check if "usertable" column family exists
    bool usertable_exists = false;
    for (const auto& name : column_family_names) {
        if (name == "usertable") {
            usertable_exists = true;
            break;
        }
    }

    if (usertable_exists) {
        std::cout << "Database contains 'usertable' column family." << std::endl;
    } else {
        std::cout << "Database does not contain 'usertable' column family." << std::endl;
    }

    return 0;
}
