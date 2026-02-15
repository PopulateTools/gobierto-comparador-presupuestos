# PostgreSQL to SQLite Migration Plan

## Overview

Migrate the Gobierto Comparador Presupuestos Rails 7.1 app from PostgreSQL to SQLite.

**Good news:** The codebase is clean - only one PostgreSQL-specific feature to handle:
- `plpgsql` extension declaration in schema (will be removed automatically by SQLite adapter)

The `activities` table (which had an `inet` column) will be removed - it's unused (no model file exists).

---

## 1. Code Changes

### 1.1 Gemfile

Replace pg gem with sqlite3:

```ruby
# Remove:
gem "pg", "~> 1.5"

# Add:
gem "sqlite3", "~> 1.7"
```

### 1.2 config/database.yml

Replace entire file:

```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: db/development.sqlite3

test:
  <<: *default
  database: db/test.sqlite3

production:
  <<: *default
  database: <%= ENV.fetch("DATABASE_PATH", "db/production.sqlite3") %>
```

### 1.3 Migration to remove unused activities table

Create `db/migrate/YYYYMMDDHHMMSS_drop_activities_table.rb`:

```ruby
class DropActivitiesTable < ActiveRecord::Migration[7.1]
  def up
    drop_table :activities
  end

  def down
    create_table :activities do |t|
      t.references :trackable, polymorphic: true
      t.references :owner, polymorphic: true
      t.references :recipient, polymorphic: true
      t.string :key
      t.text :parameters
      t.string :ip  # was inet in PostgreSQL
      t.timestamps
    end
  end
end
```

### 1.4 SQLite Configuration Initializer

Create `config/initializers/sqlite_config.rb`:

```ruby
if ActiveRecord::Base.connection.adapter_name == 'SQLite'
  ActiveRecord::Base.connection.execute("PRAGMA journal_mode=WAL")
  ActiveRecord::Base.connection.execute("PRAGMA synchronous=NORMAL")
  ActiveRecord::Base.connection.execute("PRAGMA busy_timeout=5000")
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys=ON")
end
```

---

## 2. Data Migration Script

Create `lib/tasks/db/migrate_to_sqlite.rake` with three tasks:

| Task | Purpose |
|------|---------|
| `db:migrate_to_sqlite:export` | Export PostgreSQL data to JSON via `psql` (requires `POSTGRES_SOURCE_URL`) |
| `db:migrate_to_sqlite:import` | Import JSON files into SQLite database |
| `db:migrate_to_sqlite:full` | Full migration: export → create schema → import |

The export task uses `psql` directly (not ActiveRecord) so it works even when Rails is configured for SQLite. Pass the PostgreSQL connection URL via the `POSTGRES_SOURCE_URL` environment variable.

The script handles:
- All tables (14 after activities is dropped)
- Batch inserts for performance
- Foreign key handling during import
- Skips the activities table (will be dropped)

---

## 3. Production Deployment Steps

### Step 1: Deploy Code Changes

```bash
# Merge the postgres-to-sqlite branch and deploy
cap production deploy
```

### Step 2: Export, Migrate, and Import (on the server)

```bash
# SSH into the server
ssh production-server
cd /path/to/current/release

# Backup PostgreSQL first
pg_dump -Fc -h $PG_HOST -U $PG_USERNAME gobierto_production > backup_$(date +%Y%m%d).dump

# Export data from PostgreSQL via psql, create SQLite schema, and import
POSTGRES_SOURCE_URL="postgres://user:pass@host/gobierto_production" \
  RAILS_ENV=production bin/rails db:migrate_to_sqlite:full

# Or step by step:
# POSTGRES_SOURCE_URL="..." RAILS_ENV=production bin/rails db:migrate_to_sqlite:export
# RAILS_ENV=production bin/rails db:create db:migrate
# RAILS_ENV=production bin/rails db:migrate_to_sqlite:import

# Restart application
sudo systemctl restart puma  # or however the app is managed
```

### Post-Migration Verification

```bash
# Verify record counts
RAILS_ENV=production bin/rails runner "
  puts 'Users: ' + User.count.to_s
  puts 'Sites: ' + Site.count.to_s
"

# Test critical endpoints
curl -I https://your-domain.com/
```

### SQLite Database Location

The database will be stored at `db/production.sqlite3` within the app directory.

**Note:** You'll need to either:
- Add `db/production.sqlite3` to Capistrano's `linked_files` so it persists across deployments, OR
- Symlink it to a shared directory outside the release folder

---

## 4. SQLite Considerations

| Concern | Impact | Mitigation |
|---------|--------|------------|
| Concurrent writes | Low (read-heavy app) | WAL mode enabled via initializer |
| Capistrano deploys | DB file must persist | Add to `linked_files` in deploy.rb |
| Backups | No pg_dump | Simple file copy: `cp db/production.sqlite3 backup.sqlite3` |

---

## 5. Files to Create/Modify

| File | Action |
|------|--------|
| `Gemfile` | Edit: pg → sqlite3 |
| `config/database.yml` | Replace entirely |
| `db/migrate/*_drop_activities_table.rb` | Create |
| `config/initializers/sqlite_config.rb` | Create |
| `lib/tasks/db/migrate_to_sqlite.rake` | Create |
| `config/deploy.rb` | Edit: add `db/production.sqlite3` to linked_files |

---

## 6. Verification

1. Run test suite with SQLite: `RAILS_ENV=test bin/rails db:drop db:create db:migrate && rspec`
2. Verify user login/registration works
3. Verify subscription creation works
4. Verify budget data displays (uses Elasticsearch, not SQLite)
5. Check production logs for errors after deployment
