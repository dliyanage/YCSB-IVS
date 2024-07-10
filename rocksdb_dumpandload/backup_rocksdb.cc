#include <iostream>
#include <cassert>
#include <rocksdb/db.h>
#include <rocksdb/utilities/backup_engine.h>
#include <rocksdb/options.h>
#include <vector>

using namespace rocksdb;

int main(int argc, char* argv[]) {
    // Path to the existing RocksDB database and Path to the backup directory
    // Parse command-line arguments
    std::string db_path = argv[1];
    std::string backup_path = argv[2];

    // Open the RocksDB database with column families
    DB* db;
    Options options;
    options.create_if_missing = false;

    // List of column family names
    std::vector<std::string> column_family_names = {"default", "usertable"};
    std::vector<ColumnFamilyDescriptor> column_families;
    for (const auto& name : column_family_names) {
        column_families.push_back(ColumnFamilyDescriptor(name, ColumnFamilyOptions()));
    }

    std::vector<ColumnFamilyHandle*> handles;
    Status s = DB::Open(DBOptions(), db_path, column_families, &handles, &db);

    if (!s.ok()) {
        std::cerr << "Error opening RocksDB database: " << s.ToString() << std::endl;
        return 1;
    }

    // Create the BackupEngine object
    BackupEngine* backup_engine;
    s = BackupEngine::Open(Env::Default(), BackupEngineOptions(backup_path), &backup_engine);

    if (!s.ok()) {
        std::cerr << "Error opening RocksDB backup engine: " << s.ToString() << std::endl;
        for (auto handle : handles) {
            delete handle;
        }
        delete db;
        return 1;
    }

    // Create a new backup
    s = backup_engine->CreateNewBackup(db);

    if (!s.ok()) {
        std::cerr << "Error creating RocksDB backup: " << s.ToString() << std::endl;
        for (auto handle : handles) {
            delete handle;
        }
        delete db;
        delete backup_engine;
        return 1;
    }

    std::cout << "Backup created successfully!" << std::endl;

    // Clean up
    for (auto handle : handles) {
        delete handle;
    }
    delete db;
    delete backup_engine;

    return 0;
}
