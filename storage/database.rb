require "sqlite3"

module RubyPulse
  module Storage
    class Database
      SCHEMA = <<~SQL
        CREATE TABLE IF NOT EXISTS events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_type TEXT NOT NULL,
          payload TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
        CREATE INDEX IF NOT EXISTS idx_events_created ON events(created_at);

        CREATE TABLE IF NOT EXISTS session_meta (
          key TEXT PRIMARY KEY,
          value TEXT
        );
      SQL

      RETENTION = 86_400

      def initialize(path)
        @db = SQLite3::Database.new(path)
        @db.results_as_hash = true
        @db.execute(SCHEMA)
      end

      def insert_event(type, payload = nil)
        @db.execute(
          "INSERT INTO events (event_type, payload) VALUES (?, ?)",
          [type.to_s, payload ? JSON.generate(payload) : nil]
        )
        prune
      end

      def recent_events(type: nil, limit: 200)
        sql = "SELECT * FROM events"
        clauses = []
        binds = []

        if type
          clauses << "event_type = ?"
          binds << type.to_s
        end

        sql += " WHERE #{clauses.join(" AND ")}" unless clauses.empty?
        sql += " ORDER BY created_at DESC LIMIT ?"
        binds << limit

        @db.execute(sql, binds).map do |row|
          row["payload"] = JSON.parse(row["payload"]) if row["payload"]
          row
        end
      end

      def prune
        @db.execute("DELETE FROM events WHERE created_at < datetime('now', '-24 hours')")
      end

      def close
        @db.close
      end
    end
  end
end
