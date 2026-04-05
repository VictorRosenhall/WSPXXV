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
  redirect('/users') unless session[:user_id]

  @users = db.execute("SELECT id, name FROM USERS")
  query = params[:q]

  if query && !query.strip.empty?
    @purchase = db.execute(
      "SELECT purchase.* FROM purchase
      JOIN USER_PURCHASE_REL ON purchase.id = USER_PURCHASE_REL.p_id
      WHERE USER_PURCHASE_REL.u_id = ? AND purchase.name LIKE ?",
      [session[:user_id], "%#{query}%"]
    )  else
    @purchase = db.execute(
      "SELECT purchase.* FROM purchase
      JOIN USER_PURCHASE_REL ON purchase.id = USER_PURCHASE_REL.p_id
      WHERE USER_PURCHASE_REL.u_id = ?",
      [session[:user_id]]
    )  end
  
    @participants = {}
    
    @purchase.each do |p|
      @participants[p["id"]] = db.execute("SELECT USERS.name, USER_PURCHASE_REL.status, USER_PURCHASE_REL.amount, USER_PURCHASE_REL.u_id
        FROM USER_PURCHASE_REL
        JOIN USERS ON USER_PURCHASE_REL.u_id = USERS.id
        WHERE USER_PURCHASE_REL.p_id = ?", [p["id"]])
    end

  slim(:purchase)
end

post('/purchase') do

  name = params[:name]
  cost = params[:cost]
  user_id = session[:user_id] #Används it?? TA BORT SEN!


  db.execute("INSERT INTO purchase (name, cost, user_id, category_id) VALUES (?, ?, ?, ?)", [name, cost, session[:user_id], params[:category_id]])
  id = db.last_insert_row_id
  split = params[:participants] ? cost.to_f / (params[:participants].length + 1) : cost.to_f
  add_participant(id, session[:user_id], split)
  
  if params[:participants]
    params[:participants].each do |user_id|
      add_participant(id, user_id.to_i, split)
    end
  end
  redirect('/purchase')
end

post('/purchase/:id/delete') do
  id = params[:id]

  db.execute("DELETE FROM purchase WHERE id = ? AND user_id = ?", [id, session[:user_id]])

  redirect('/purchase')
end

get('/purchase/:id/edit') do
  redirect('/users') unless session[:user_id]
  id = params[:id].to_i

  @purchase = db.execute("SELECT * FROM purchase WHERE id = ?", [id]).first

  slim(:edit)
end

post('/purchase/:id/update') do
  id = params[:id].to_i
  name = params[:name]
  cost = params[:cost]

  db.execute("UPDATE purchase SET name=?, cost=? WHERE id=? AND user_id=?",[name, cost, id, session[:user_id]])

  redirect('/purchase')
end

get('/users') do
  slim(:register)
end

post('/users') do
  user = params["name"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]

  result = db.execute("SELECT id FROM USERS WHERE name=?", [user])

  if result.empty?
    if pwd == pwd_confirm
      pwd_digest = BCrypt::Password.create(pwd)
      db.execute("INSERT INTO USERS(name, pwd_digest) VALUES(?,?)", [user,pwd_digest])
      redirect('/users')
    else
      redirect('/error') #om lösenord it matchar
    end
  else
    redirect('/users') #om d redan finns
  end
  slim(:register)
end

post('/login') do
  user = params["name"]
  pwd = params["pwd"]

  result = db.execute("SELECT id, pwd_digest, role FROM USERS WHERE name=?", [user])

  if result.empty?
    redirect('/error')
  end
    
  user_id = result.first["id"]
  pwd_digest = result.first["pwd_digest"]

  if BCrypt::Password.new(pwd_digest) == pwd
    session[:user_id] = user_id
    session[:role] = result.first["role"]
    redirect('/purchase')
  else
    redirect('/error')
  end
end

get('/logout') do
  session.clear
  redirect('/users')
end

get('/admin') do
  redirect('/purchase') unless session[:role] == 1

  @purchases = db.execute("SELECT purchase.*, USERS.name AS username FROM purchase
    JOIN USERS ON purchase.user_id = USERS.id")
  
  @participants = {}
  @purchases.each do |purchase|
    @participants[purchase["id"]] = db.execute("SELECT USERS.name, USER_PURCHASE_REL.status, USER_PURCHASE_REL.amount
      FROM USER_PURCHASE_REL
      JOIN USERS ON USER_PURCHASE_REL.u_id = USERS.id
      WHERE USER_PURCHASE_REL.p_id = ?", [purchase["id"]])
  end

  slim(:admin)
end

post('/purchase/:id/pay') do
  id = params[:id].to_i
  db.execute("UPDATE USER_PURCHASE_REL SET status = 'paid' WHERE p_id = ? AND u_id = ?", [id, session[:user_id]])
  redirect('/purchase')
end