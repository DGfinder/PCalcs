import Foundation
import GRDB

// MARK: - Database Schema

public struct DatabaseSchema {
    
    // MARK: - Schema Version
    
    public static let currentVersion: Int = 1
    
    // MARK: - Database Setup
    
    public static func setupDatabase(_ db: Database) throws {
        try createPerformanceDataTables(db)
        try createWeatherTables(db)
        try createHistoryTables(db)
        try createSettingsTables(db)
        try createIndexes(db)
    }
    
    // MARK: - Performance Data Tables
    
    private static func createPerformanceDataTables(_ db: Database) throws {
        
        // Aircraft limits table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS aircraft_limits (
                aircraft_type TEXT PRIMARY KEY,
                max_takeoff_weight_kg REAL NOT NULL,
                max_landing_weight_kg REAL NOT NULL,
                max_zero_fuel_weight_kg REAL NOT NULL,
                min_operating_weight_kg REAL NOT NULL,
                max_pressure_altitude_m REAL NOT NULL,
                min_pressure_altitude_m REAL NOT NULL,
                max_temperature_c REAL NOT NULL,
                min_temperature_c REAL NOT NULL,
                max_wind_kt REAL NOT NULL,
                max_tailwind_kt REAL NOT NULL,
                max_slope_percent REAL NOT NULL,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // Performance data points table (main performance data)
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS performance_data_points (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                aircraft_type TEXT NOT NULL,
                configuration_id TEXT NOT NULL,
                weight_kg REAL NOT NULL,
                pressure_altitude_m REAL NOT NULL,
                temperature_c REAL NOT NULL,
                todr_m REAL,
                asdr_m REAL,
                bfl_m REAL,
                ldr_m REAL,
                climb_gradient_percent REAL,
                v_speeds_json TEXT,
                data_pack_version TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (aircraft_type) REFERENCES aircraft_limits(aircraft_type)
            )
        """)
        
        // Flight configurations table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS flight_configurations (
                id TEXT PRIMARY KEY,
                aircraft_type TEXT NOT NULL,
                flap_setting TEXT NOT NULL,
                landing_gear TEXT NOT NULL,
                anti_ice_on BOOLEAN NOT NULL DEFAULT FALSE,
                bleed_air_on BOOLEAN NOT NULL DEFAULT TRUE,
                description TEXT,
                is_default BOOLEAN NOT NULL DEFAULT FALSE,
                FOREIGN KEY (aircraft_type) REFERENCES aircraft_limits(aircraft_type)
            )
        """)
        
        // V-speeds table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS v_speeds_data (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                aircraft_type TEXT NOT NULL,
                configuration_id TEXT NOT NULL,
                weight_kg REAL NOT NULL,
                vr_kt REAL,
                v2_kt REAL,
                vref_kt REAL,
                vapp_kt REAL,
                data_pack_version TEXT NOT NULL,
                FOREIGN KEY (aircraft_type) REFERENCES aircraft_limits(aircraft_type),
                FOREIGN KEY (configuration_id) REFERENCES flight_configurations(id)
            )
        """)
        
        // Correction factors table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS correction_factors (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                aircraft_type TEXT NOT NULL,
                phase TEXT NOT NULL,
                parameter_type TEXT NOT NULL,
                parameter_value REAL NOT NULL,
                correction_factor REAL NOT NULL,
                valid_from TEXT NOT NULL,
                valid_to TEXT,
                data_pack_version TEXT NOT NULL,
                FOREIGN KEY (aircraft_type) REFERENCES aircraft_limits(aircraft_type)
            )
        """)
        
        // Data pack versions table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS data_pack_versions (
                version TEXT PRIMARY KEY,
                aircraft_type TEXT NOT NULL,
                description TEXT,
                release_date TEXT NOT NULL,
                is_active BOOLEAN NOT NULL DEFAULT FALSE,
                checksum TEXT,
                size_bytes INTEGER,
                installed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)
    }
    
    // MARK: - Weather Tables
    
    private static func createWeatherTables(_ db: Database) throws {
        
        // Weather cache table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS weather_cache (
                icao TEXT PRIMARY KEY,
                metar_raw TEXT,
                taf_raw TEXT,
                parsed_data_json TEXT,
                issued_at TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                source TEXT NOT NULL,
                ttl_seconds INTEGER NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // Airport information table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS airports (
                icao TEXT PRIMARY KEY,
                iata TEXT,
                name TEXT NOT NULL,
                city TEXT,
                country TEXT,
                latitude REAL,
                longitude REAL,
                elevation_m REAL,
                timezone TEXT,
                is_active BOOLEAN NOT NULL DEFAULT TRUE,
                runway_info_json TEXT,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)
    }
    
    // MARK: - History Tables
    
    private static func createHistoryTables(_ db: Database) throws {
        
        // Calculation history table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS calculation_history (
                id TEXT PRIMARY KEY,
                calculation_type TEXT NOT NULL,
                aircraft_type TEXT NOT NULL,
                inputs_json TEXT NOT NULL,
                results_json TEXT NOT NULL,
                evidence_hash TEXT,
                evidence_signature TEXT,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
                tags_json TEXT,
                notes TEXT,
                shared_at TEXT,
                FOREIGN KEY (aircraft_type) REFERENCES aircraft_limits(aircraft_type)
            )
        """)
        
        // Calculation sessions table (for grouping related calculations)
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS calculation_sessions (
                id TEXT PRIMARY KEY,
                name TEXT,
                description TEXT,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                is_active BOOLEAN NOT NULL DEFAULT TRUE
            )
        """)
        
        // Session calculations junction table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS session_calculations (
                session_id TEXT NOT NULL,
                calculation_id TEXT NOT NULL,
                order_index INTEGER NOT NULL,
                PRIMARY KEY (session_id, calculation_id),
                FOREIGN KEY (session_id) REFERENCES calculation_sessions(id),
                FOREIGN KEY (calculation_id) REFERENCES calculation_history(id)
            )
        """)
    }
    
    // MARK: - Settings Tables
    
    private static func createSettingsTables(_ db: Database) throws {
        
        // App settings table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS app_settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                value_type TEXT NOT NULL,
                description TEXT,
                is_user_configurable BOOLEAN NOT NULL DEFAULT TRUE,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        // User preferences table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS user_preferences (
                category TEXT NOT NULL,
                key TEXT NOT NULL,
                value TEXT NOT NULL,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (category, key)
            )
        """)
        
        // Cloud sync state table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS cloud_sync_state (
                table_name TEXT PRIMARY KEY,
                last_sync_at TEXT,
                last_sync_hash TEXT,
                pending_changes INTEGER NOT NULL DEFAULT 0,
                sync_enabled BOOLEAN NOT NULL DEFAULT FALSE,
                conflict_resolution TEXT NOT NULL DEFAULT 'client_wins'
            )
        """)
    }
    
    // MARK: - Indexes
    
    private static func createIndexes(_ db: Database) throws {
        
        // Performance data indexes
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_perf_aircraft_weight ON performance_data_points(aircraft_type, weight_kg)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_perf_aircraft_config ON performance_data_points(aircraft_type, configuration_id)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_perf_conditions ON performance_data_points(pressure_altitude_m, temperature_c)")
        
        // V-speeds indexes
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_vspeeds_aircraft_weight ON v_speeds_data(aircraft_type, weight_kg)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_vspeeds_config ON v_speeds_data(configuration_id)")
        
        // Correction factors indexes
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_corrections_aircraft_phase ON correction_factors(aircraft_type, phase)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_corrections_param ON correction_factors(parameter_type, parameter_value)")
        
        // Weather indexes
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_weather_expires ON weather_cache(expires_at)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_weather_issued ON weather_cache(issued_at)")
        
        // History indexes
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_history_created ON calculation_history(created_at)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_history_aircraft ON calculation_history(aircraft_type)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_history_type ON calculation_history(calculation_type)")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_history_not_deleted ON calculation_history(is_deleted) WHERE is_deleted = FALSE")
        
        // Session indexes
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_sessions_active ON calculation_sessions(is_active) WHERE is_active = TRUE")
        try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_session_calcs_order ON session_calculations(session_id, order_index)")
    }
    
    // MARK: - Migration Support
    
    public static func migrateDatabase(_ migrator: inout DatabaseMigrator) {
        migrator.registerMigration("v1") { db in
            try setupDatabase(db)
            try insertDefaultData(db)
        }
        
        // Future migrations would be added here
        // migrator.registerMigration("v2") { db in ... }
    }
    
    // MARK: - Default Data
    
    private static func insertDefaultData(_ db: Database) throws {
        
        // Insert Beechcraft 1900D limits
        try db.execute(sql: """
            INSERT OR REPLACE INTO aircraft_limits (
                aircraft_type, max_takeoff_weight_kg, max_landing_weight_kg,
                max_zero_fuel_weight_kg, min_operating_weight_kg,
                max_pressure_altitude_m, min_pressure_altitude_m,
                max_temperature_c, min_temperature_c,
                max_wind_kt, max_tailwind_kt, max_slope_percent
            ) VALUES (
                'beechcraft_1900d', 7802, 7530, 6804, 4100,
                3048, -305, 50, -40, 35, 10, 2.0
            )
        """)
        
        // Insert default flight configurations
        try db.execute(sql: """
            INSERT OR REPLACE INTO flight_configurations (
                id, aircraft_type, flap_setting, landing_gear,
                anti_ice_on, bleed_air_on, description, is_default
            ) VALUES 
            ('takeoff_normal', 'beechcraft_1900d', 'approach', 'retracted', FALSE, TRUE, 'Normal Takeoff', TRUE),
            ('landing_normal', 'beechcraft_1900d', 'landing', 'extended', FALSE, TRUE, 'Normal Landing', TRUE),
            ('takeoff_anti_ice', 'beechcraft_1900d', 'approach', 'retracted', TRUE, TRUE, 'Takeoff with Anti-Ice', FALSE)
        """)
        
        // Insert default app settings
        let defaultSettings = [
            ("units_weight", "kg", "text", "Weight units (kg/lbs)"),
            ("units_distance", "m", "text", "Distance units (m/ft)"),
            ("units_temperature", "c", "text", "Temperature units (c/f)"),
            ("units_wind", "kt", "text", "Wind units (kt/mps)"),
            ("cache_duration_weather", "600", "integer", "Weather cache duration in seconds"),
            ("calculation_timeout", "30", "integer", "Calculation timeout in seconds"),
            ("evidence_enabled", "true", "boolean", "Enable calculation evidence"),
            ("auto_sync_enabled", "false", "boolean", "Enable automatic cloud sync"),
            ("performance_warnings", "true", "boolean", "Show performance warnings")
        ]
        
        for (key, value, type, description) in defaultSettings {
            try db.execute(sql: """
                INSERT OR REPLACE INTO app_settings (key, value, value_type, description)
                VALUES (?, ?, ?, ?)
            """, arguments: [key, value, type, description])
        }
        
        // Initialize data pack version
        try db.execute(sql: """
            INSERT OR REPLACE INTO data_pack_versions (
                version, aircraft_type, description, release_date, is_active
            ) VALUES (
                'built-in-1.0.0', 'beechcraft_1900d', 'Built-in performance data', 
                datetime('now'), TRUE
            )
        """)
        
        // Initialize cloud sync state
        let tables = [
            "calculation_history", "calculation_sessions", "session_calculations",
            "app_settings", "user_preferences"
        ]
        
        for table in tables {
            try db.execute(sql: """
                INSERT OR REPLACE INTO cloud_sync_state (table_name, sync_enabled)
                VALUES (?, FALSE)
            """, arguments: [table])
        }
    }
}

// MARK: - Database Migration Extensions

extension DatabaseMigrator {
    
    /// Configure the migrator with all app migrations
    public static func setupAppMigrations() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        migrator.eraseDatabaseOnSchemaConflict = true
        #endif
        
        DatabaseSchema.migrateDatabase(&migrator)
        
        return migrator
    }
}