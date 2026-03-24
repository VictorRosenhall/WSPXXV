require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions

DB_FILE = "db/databas.db"

get('/') do
  slim(:index)
end

get('/purchase') do

  query = params[:q]
  #db = db()
  if query && !query.strip.empty?
    @purchase = db.execute("SELECT * FROM purchase WHERE name LIKE ?", ["%#{query}%"])
  else
    @purchase = db.execute("SELECT * FROM purchase")
  end

  slim(:purchase)
end

post('/purchase') do

  name = params[:name]
  cost = params[:cost]

  db.execute("INSERT INTO purchase (name, cost) VALUES (?, ?)", [name, cost])

  redirect('/purchase')
end

post('/purchase/:id/delete') do
  id = params[:id]

  db.execute("DELETE FROM purchase WHERE id = ?", [id])

  redirect('/purchase')
end

get('/purchase/:id/edit') do
  id = params[:id].to_i

  @purchase = db.execute("SELECT * FROM purchase WHERE id = ?", [id]).first

  slim(:edit)
end

post('/purchase/:id/update') do
  id = params[:id].to_i
  name = params[:name]
  cost = params[:cost]

  db.execute("UPDATE purchase SET name=?, cost=? WHERE id=?", [name, cost, id])

  redirect('/purchase')
end

get('/users') do
  users = params["users"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]
  result=db.execute("SELECT id FROM users WHERE users=?",users)

  if result.empty?
    if pwd==pwd_confirm
      pwd_digest=BCrypt::Password.create(pwd)
      db.execute("INSERT INTO users(users,pwd_digest) VALUES(?,?)", [users,pwd_digest])
      redirect('/welcome')
    else
      redirect('/error') #om lösenord it matchar
    end
  else
    redirect('/login') #om d redan finns
  end
  slim(:register)
end

get('/login') do
    users = params["users"]
    pwd = params["pwd"]
    result=db.execute("SELECT id, pwd_digest FROM users WHERE users=?",users)

    if result.empty?
      redirect('/error')
    end
    
    users_id = result.first["id"]
    pwd_digest = result.first["pwd_digest"]

    if BCrypt::Password.new(pwd_digest) == pwd
      session[:users_id] = users_id
      redirect('/welcome')
    else
      redirect('/error')
    end
  end