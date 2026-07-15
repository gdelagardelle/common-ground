import Foundation
import SwiftData

public enum CommonGroundSchemaV1: VersionedSchema {
    nonisolated(unsafe) public static var versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        CommonGroundSchema.models
    }
}

public enum CommonGroundMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [CommonGroundSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}
