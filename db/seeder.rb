require 'sqlite3'
require 'bcrypt'

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
              cost REAL NOT NULL,
              user_id INTEGER NOT NULL,
              category_id INTEGER,
              FOREIGN KEY (user_id) REFERENCES USERS(id),
              FOREIGN KEY (category_id) REFERENCES CATEGORY(id)
  )')

  db.execute('CREATE TABLE IF NOT EXISTS CATEGORY (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
  )')

  db.execute('CREATE TABLE IF NOT EXISTS USER_PURCHASE_REL (
              p_id INTEGER,
              u_id INTEGER,
              status TEXT,
              amount REAL,
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

  pwd = BCrypt::Password.create("admin")
  pwd2 = BCrypt::Password.create("eliasgoon")
  pwd3 = BCrypt::Password.create("sebgoon")

  db.execute('INSERT INTO USERS (name, pwd_digest) VALUES (?, ?)', ["Admin_test", pwd])
  db.execute('INSERT INTO USERS (name, pwd_digest) VALUES (?, ?)', ["eliasgoon", pwd2])
  db.execute('INSERT INTO USERS (name, pwd_digest) VALUES (?, ?)', ["sebgoon", pwd3])

  db.execute('INSERT INTO CATEGORY (name) VALUES (?)', ["FOOD"])

  db.execute('INSERT INTO purchase (name, cost, user_id, category_id) VALUES (?, ?, ?, ?)', ["Cheese burgir", 150, 1, 1])

  rel_count = db.execute("SELECT COUNT(*) AS cnt FROM USER_PURCHASE_REL").first["cnt"]

  #borde vara onödiga, gör inget?
  if rel_count == 0
    db.execute('INSERT INTO USER_PURCHASE_REL (p_id, u_id, status, amount) VALUES (?, ?, ?, ?)', [1, 1, "paid", 100])
    db.execute('INSERT INTO USER_PURCHASE_REL (p_id, u_id, status, amount) VALUES (?, ?, ?, ?)', [1, 2, "unpaid", 100])
    db.execute('INSERT INTO USER_PURCHASE_REL (p_id, u_id, status, amount) VALUES (?, ?, ?, ?)', [1, 3, "unpaid", 100])
  end
end
# Kör seed
seed!(@db)