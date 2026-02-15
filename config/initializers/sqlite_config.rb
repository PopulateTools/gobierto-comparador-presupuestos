# ABOUTME: SQLite performance and reliability configuration
# ABOUTME: Enables WAL mode for better concurrency and foreign key enforcement

Rails.application.config.after_initialize do
  if ActiveRecord::Base.connection.adapter_name == "SQLite"
    ActiveRecord::Base.connection.execute("PRAGMA journal_mode=WAL")
    ActiveRecord::Base.connection.execute("PRAGMA synchronous=NORMAL")
    ActiveRecord::Base.connection.execute("PRAGMA busy_timeout=5000")
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys=ON")
  end
end
