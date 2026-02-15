# ABOUTME: Rake tasks for migrating data from PostgreSQL to SQLite
# ABOUTME: Exports data from PostgreSQL via psql, imports into SQLite via ActiveRecord

namespace :db do
  namespace :migrate_to_sqlite do
    desc "Export data from PostgreSQL to JSON files (requires POSTGRES_SOURCE_URL)"
    task export: :environment do
      require "json"
      require "fileutils"

      postgres_url = ENV["POSTGRES_SOURCE_URL"]
      abort "POSTGRES_SOURCE_URL is required (e.g. postgres://user:pass@localhost/dbname)" unless postgres_url

      export_dir = Rails.root.join("tmp", "pg_export")
      FileUtils.mkdir_p(export_dir)

      skip_tables = %w[schema_migrations ar_internal_metadata activities]

      tables_sql = "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename"
      tables_output = `psql "#{postgres_url}" -t -A -c "#{tables_sql}" 2>&1`
      abort "Failed to connect to PostgreSQL: #{tables_output}" unless $?.success?

      tables = tables_output.strip.split("\n").reject { |t| skip_tables.include?(t) }

      tables.each do |table|
        puts "Exporting #{table}..."

        json_output = `psql "#{postgres_url}" -t -A -c "SELECT COALESCE(json_agg(t), '[]'::json) FROM #{table} t" 2>&1`
        abort "Failed to export #{table}: #{json_output}" unless $?.success?

        data = JSON.parse(json_output.strip)

        File.write(
          export_dir.join("#{table}.json"),
          JSON.pretty_generate(data)
        )

        puts "  Exported #{data.length} records"
      end

      migrations_output = `psql "#{postgres_url}" -t -A -c "SELECT json_agg(version ORDER BY version) FROM schema_migrations" 2>&1`
      abort "Failed to export schema_migrations: #{migrations_output}" unless $?.success?

      migrations = JSON.parse(migrations_output.strip)

      File.write(
        export_dir.join("schema_migrations.json"),
        JSON.pretty_generate(migrations)
      )

      puts "\nExport complete! Files saved to #{export_dir}"
    end

    desc "Import data from JSON files into SQLite"
    task import: :environment do
      require "json"

      export_dir = Rails.root.join("tmp", "pg_export")

      unless Dir.exist?(export_dir)
        abort "Export directory not found: #{export_dir}\nRun db:migrate_to_sqlite:export first (on PostgreSQL)"
      end

      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")

      tables = ActiveRecord::Base.connection.tables - ["schema_migrations", "ar_internal_metadata"]

      tables.each do |table|
        json_file = export_dir.join("#{table}.json")
        next unless File.exist?(json_file)

        puts "Importing #{table}..."

        data = JSON.parse(File.read(json_file))

        if data.empty?
          puts "  No records to import"
          next
        end

        ActiveRecord::Base.connection.execute("DELETE FROM #{table}")

        begin
          ActiveRecord::Base.connection.execute(
            "DELETE FROM sqlite_sequence WHERE name = '#{table}'"
          )
        rescue ActiveRecord::StatementInvalid
          # Table might not have autoincrement
        end

        columns = data.first.keys

        data.each_slice(100) do |batch|
          values = batch.map do |record|
            columns.map { |col| ActiveRecord::Base.connection.quote(record[col]) }.join(", ")
          end

          sql = "INSERT INTO #{table} (#{columns.join(', ')}) VALUES "
          sql += values.map { |v| "(#{v})" }.join(", ")

          ActiveRecord::Base.connection.execute(sql)
        end

        puts "  Imported #{data.length} records"
      end

      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")

      puts "\nImport complete!"
      puts "\nVerifying record counts..."
      tables.each do |table|
        count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) as cnt FROM #{table}").first["cnt"]
        puts "  #{table}: #{count} records"
      end
    end

    desc "Full migration: export from PostgreSQL, setup SQLite, and import"
    task full: :environment do
      puts "=== PostgreSQL to SQLite Migration ==="
      puts ""
      puts "This task will:"
      puts "1. Export all data from PostgreSQL (via POSTGRES_SOURCE_URL)"
      puts "2. Setup SQLite schema and import data"
      puts ""
      print "Continue? (yes/no): "

      unless $stdin.gets.chomp.downcase == "yes"
        abort "Migration cancelled"
      end

      puts "\n=== Step 1: Exporting from PostgreSQL ==="
      Rake::Task["db:migrate_to_sqlite:export"].invoke

      puts "\n=== Step 2: Setting up SQLite schema ==="
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke

      puts "\n=== Step 3: Importing data ==="
      Rake::Task["db:migrate_to_sqlite:import"].invoke
    end
  end
end
