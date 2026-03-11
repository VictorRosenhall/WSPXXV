require 'sqlite3'

db = SQLite3::Database.new("db/databas.db")

def seed!(db)
  puts "Using db file: db/databas.db" 
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
  db.execute('CREATE TABLE USERS (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              pwd_digest TEXT)')
  db.execute('CREATE TABLE purchase (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              type_id TEXT)')
  db.execute('CREATE TABLE CATEGORY (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL)')
  db.execute('CREATE TABLE USER_PURCHASE_REL (
              p_id INTEGER,
              u_id INTEGER,
              PRIMARY KEY (p_id, u_id),
              FOREIGN KEY (p_id) REFERENCES purchase(id)
                ON DELETE CASCADE,
              FOREIGN KEY (u_id) REFERENCES USERS(id)
                ON DELETE CASCADE
              )')
end

def populate_tables(db)
  db.execute('INSERT INTO USERS (name, pwd_digest) VALUES ("Elias", "Benis")')
  db.execute('INSERT INTO purchase (name, type_id) VALUES ("Cheese burgir", "3")')  
  db.execute('INSERT INTO CATEGORY (name) VALUES ("FOOD")')
end


seed!(db)





