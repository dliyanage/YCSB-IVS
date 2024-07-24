#include <iostream>
#include <rocksdb/db.h>
#include <rocksdb/utilities/backup_engine.h>
#include <vector>
#include <cstdlib>

using namespace rocksdb;

int main(int argc, char* argv[]) {
    // Check if the correct number of arguments is provided
    if (argc != 4) {
        std::cerr << "Usage: " << argv[0] << " <db_path> <backup_path> <backup_id_to_restore>" << std::endl;
        return 1;
    }

    // Parse command-line arguments
    std::string db_path = argv[1];
    std::string backup_path = argv[2];
    uint32_t backup_id_to_restore = std::stoi(argv[3]);

    // Open the backup engine
    BackupEngine* backup_engine;
    Status s = BackupEngine::Open(Env::Default(), BackupEngineOptions(backup_path), &backup_engine);

    if (!s.ok()) {
        std::cerr << "Error opening RocksDB backup engine: " << s.ToString() << std::endl;
        return 1;
    }

    // List all available backups
    std::vector<BackupInfo> backup_info;
    backup_engine->GetBackupInfo(&backup_info);

    std::cout << "Available backups:" << std::endl;
    for (const auto& info : backup_info) {
        std::cout << "Backup ID: " << info.backup_id << ", Timestamp: " << info.timestamp
                  << ", Size: " << info.size << ", Number of files: " << info.number_files << std::endl;
    }

    // Restore from the specified backup ID
    s = backup_engine->RestoreDBFromBackup(backup_id_to_restore, db_path, db_path);

    if (!s.ok()) {
        std::cerr << "Error restoring RocksDB backup: " << s.ToString() << std::endl;
        delete backup_engine;
        return 1;
    }

    std::cout << "Backup restored successfully!" << std::endl;

    // Open the RocksDB database with all column families
    DB* db;
    Options options;
    options.create_if_missing = false;

    // Get the list of column families from the restored database
    std::vector<std::string> column_family_names;
    s = DB::ListColumnFamilies(options, db_path, &column_family_names);

    if (!s.ok()) {
        std::cerr << "Error listing column families in RocksDB: " << s.ToString() << std::endl;
        delete backup_engine;
        return 1;
    }

    // Ensure 'usertable' is present in the column families
    bool usertable_found = false;
    for (const auto& name : column_family_names) {
        if (name == "usertable") {
            usertable_found = true;
            break;
        }
    }

    if (!usertable_found) {
        std::cerr << "Error: 'usertable' column family not found in the restored database." << std::endl;
        delete backup_engine;
        return 1;
    }

    // Open the database with all found column families
    std::vector<ColumnFamilyHandle*> handles;
    std::vector<ColumnFamilyDescriptor> column_families;
    for (const auto& name : column_family_names) {
        column_families.push_back(ColumnFamilyDescriptor(name, ColumnFamilyOptions()));
    }

    s = DB::Open(DBOptions(), db_path, column_families, &handles, &db);

    if (!s.ok()) {
        std::cerr << "Error opening RocksDB database: " << s.ToString() << std::endl;
        delete backup_engine;
        return 1;
    }

    std::cout << "RocksDB database opened successfully!" << std::endl;

    // Clean up
    for (auto handle : handles) {
        delete handle;
    }
    delete db;
    delete backup_engine;

    return 0;
}
