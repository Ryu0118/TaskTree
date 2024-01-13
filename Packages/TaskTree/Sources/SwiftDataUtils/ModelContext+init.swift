import Foundation
import SwiftData

// ref: https://github.com/yusuga/swiftdata-101/blob/main/SwiftData101/Extension/ModelContext%2BSwiftData101.swift
public extension ModelContext {
    enum StorageType {
        case inMemory
        case file
    }

    convenience init(
        for types: any PersistentModel.Type...,
        storageType: StorageType,
        shouldDeleteOldFile: Bool,
        fileName: String = #function
    ) throws {
        let schema = Schema(types)

        let sqliteURL = URL.documentsDirectory
            .appending(component: fileName)
            .appendingPathExtension("sqlite")

        if shouldDeleteOldFile {
            let fileManager = FileManager.default

            if fileManager.fileExists(atPath: sqliteURL.path) {
                try fileManager.removeItem(at: sqliteURL)
            }
        }

        let modelConfiguration: ModelConfiguration = {
            switch storageType {
            case .inMemory:
                ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
            case .file:
                ModelConfiguration(
                    schema: schema,
                    url: sqliteURL,
                    cloudKitDatabase: .automatic
                )
            }
        }()

        let modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )

        self.init(modelContainer)
    }
}
