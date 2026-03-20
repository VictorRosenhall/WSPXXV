require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

DB_FILE = "db/databas.db"

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
  db = SQLite3::Database.new("db/databas.db")

  name = params[:name]
  cost = params[:cost]

  db.execute("INSERT INTO purchase (name, cost) VALUES (?, ?)", [name, cost])

  redirect('/purchase')
end

post('/purchase/:id/delete') do
  db = SQLite3::Database.new("db/databas.db")

  id = params[:id]

  db.execute("DELETE FROM purchase WHERE id = ?", [id])

  redirect('/purchase')
end