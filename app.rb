require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

DB_FILE = "db/databas.db"

def db
  return @db if @db

  @db = SQLite3::Database.new(DB_FILE)
  @db.results_as_hash = true
  ensure_tables_exist
  seed_if_empty
  @db
end

# Se till att tabellerna finns
def ensure_tables_exist
  db = @db
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS USERS (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      pwd_digest TEXT
    )
  SQL

  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS purchase (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type_id TEXT
    )
  SQL

  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS CATEGORY (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
  SQL

  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS USER_PURCHASE_REL (
      p_id INTEGER,
      u_id INTEGER,
      PRIMARY KEY (p_id, u_id),
      FOREIGN KEY (p_id) REFERENCES purchase(id) ON DELETE CASCADE,
      FOREIGN KEY (u_id) REFERENCES USERS(id) ON DELETE CASCADE
    )
  SQL
end

# Seed initial data om tabeller är tomma
def seed_if_empty
  db = @db
  users_count = db.execute("SELECT COUNT(*) AS cnt FROM USERS").first["cnt"]
  purchase_count = db.execute("SELECT COUNT(*) AS cnt FROM purchase").first["cnt"]
  category_count = db.execute("SELECT COUNT(*) AS cnt FROM CATEGORY").first["cnt"]

  db.execute('INSERT INTO USERS (name, pwd_digest) VALUES (?, ?)', ["Elias", "Benis"]) if users_count == 0
  db.execute('INSERT INTO purchase (name, type_id) VALUES (?, ?)', ["Cheese burger", "3"]) if purchase_count == 0
  db.execute('INSERT INTO CATEGORY (name) VALUES (?)', ["FOOD"]) if category_count == 0
end

# ------------------------
# Routes
# ------------------------

get('/') do
  slim(:index)
end

get('/purchase') do
  query = params[:q]

  if query && !query.strip.empty?
    @purchase = db.execute("SELECT * FROM purchase WHERE name LIKE ?", ["%#{query}%"])
  else
    @purchase = db.execute("SELECT * FROM purchase")
  end

  slim(:purchase)
end

post('/purchase') do
  name = params[:q]
  type_id = params[:description] || "0"

  db.execute("INSERT INTO purchase (name, type_id) VALUES (?, ?)", [name, type_id])

  redirect('/purchase')
end