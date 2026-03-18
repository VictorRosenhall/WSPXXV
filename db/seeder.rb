require 'sqlite3'

DB_FILE = "databas.db"
# Öppna databasen
@db = SQLite3::Database.new(DB_FILE)
@db.results_as_hash = true

def seed!(db)
  puts "Using db file: #{DB_FILE}"

  puts "🧹 Dropping old tables..."
  drop_tables(db)

  puts "🧱 Creating tables..."
  create_tables(db)

  puts "🍎 Populating tables..."
  populate_tables(db)

  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS USER_PURCHASE_REL')
  db.execute('DROP TABLE IF EXISTS USERS')
  db.execute('DROP TABLE IF EXISTS purchase')
  db.execute('DROP TABLE IF EXISTS CATEGORY')
end

def create_tables(db)
  db.execute('CREATE TABLE IF NOT EXISTS USERS (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              pwd_digest TEXT
  )')

  db.execute('CREATE TABLE IF NOT EXISTS purchase (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              type_id TEXT
  )')

  db.execute('CREATE TABLE IF NOT EXISTS CATEGORY (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
  )')

  db.execute('CREATE TABLE IF NOT EXISTS USER_PURCHASE_REL (
              p_id INTEGER,
              u_id INTEGER,
              PRIMARY KEY (p_id, u_id),
              FOREIGN KEY (p_id) REFERENCES purchase(id) ON DELETE CASCADE,
              FOREIGN KEY (u_id) REFERENCES USERS(id) ON DELETE CASCADE
  )')
end

def populate_tables(db)
  # Skapa exempeldata om tabellen är tom
  users_count = db.execute("SELECT COUNT(*) AS cnt FROM USERS").first["cnt"]
  purchase_count = db.execute("SELECT COUNT(*) AS cnt FROM purchase").first["cnt"]
  category_count = db.execute("SELECT COUNT(*) AS cnt FROM CATEGORY").first["cnt"]

  db.execute('INSERT INTO USERS (name, pwd_digest) VALUES (?, ?)', ["Elias", "Benis"]) if users_count == 0
  db.execute('INSERT INTO purchase (name, type_id) VALUES (?, ?)', ["Cheese burger", "3"]) if purchase_count == 0
  db.execute('INSERT INTO CATEGORY (name) VALUES (?)', ["FOOD"]) if category_count == 0
end

# Kör seed
seed!(@db)