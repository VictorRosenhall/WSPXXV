require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
enable :session

DB_PATH = "db/databas.db"

def db
  return @db if @db

  @db = SQLite3::Database.new(DB_PATH)
  @db.results_as_hash = true
  @db
end

get('/') do
  slim(:index)
end

#get ('/purchase') do
#  query = params[:q]
#
#  if query && !query.strip.empty?
#    @purchase = db.execute(
#      "SELECT * FROM PURCHASE WHERE name LIKE ?",
#      ["%#{query}%"]
#    )
#  else
#    @purchase = db.execute("SELECT * FROM PURCHASE")
#  end
#
#  slim(:purchase)
#end

get('/purchase') do
  query = params[:q]

  if query && !query.strip.empty?
    @purchase = db.execute(
      "SELECT * FROM purchase WHERE name LIKE ?",
      ["%#{query}%"]
    )
  else
    @purchase = db.execute("SELECT * FROM purchase")
  end

  slim(:purchase)
end

post('/purchase') do
  name = params[:q]
  description = params[:description]

  db.execute("INSERT INTO purchase (name) VALUES (?)", [name])

  redirect('/purchase')
end

#post('/todos/:id/delete') do
#  db = SQLite3::Database.new('db/todos.db') # koppling till databasen
#  #extrahera id för att få rätt frukt
#  denna_ska_bort = params[:id]
#  #ta bort från db
#  db.execute("DELETE FROM todos WHERE id = ?", [denna_ska_bort])
#  redirect('/todos')
#end
#
#get('/todos/:id/edit') do
#  db = SQLite3::Database.new("db/todos.db")
#  db.results_as_hash = true
#
#  id = params[:id].to_i
#  @todo = db.execute("SELECT * FROM todos WHERE id = ?", [id]).first
#
#  slim(:edit)
#end
#
#post('/todos/:id/update') do
#  db = SQLite3::Database.new("db/todos.db")
#
#  id = params[:id].to_i
#  name = params[:name]
#  description = params[:description]
#
#  db.execute("UPDATE todos SET name=?, description=? WHERE id=?", [name, description, id])
#
#  redirect('/todos')
#end
#
#post('/todos') do
#  db = SQLite3::Database.new("db/todos.db")
#  name = params[:q]
#  description = params[:description]
#  db.execute("INSERT INTO todos (name, description) VALUES (?, ?)", [name, description])
#  redirect('/todos')
#end
#
#get('/user') do
#  user = params["user"]
#  pwd = params["pwd"]
#  pwd_confirm = params["pwd_confirm"]
#
#  db = SQLite3::Database.new("db/store.db")
#  result=db.execute("SELECT id FROM users WHERE user=?",user)
#
#  if result.empty?
#    if pwd==pwd_confirm
#      pwd_digest=BCrypt::Password.create(pwd)
#      db.execute("INSERT INTO users(user,pwd_digest) VALUES(?,?)", [user,pwd_digest])
#      redirect('/welcome')
#    else
#      redirect('/error') #om lösenord it matchar
#    end
#  else
#    redirect('/login') #om d redan finns
#  end
#  slim(:register)
#end
#
#get('/login') do
#    user = params["user"]
#    pwd = params["pwd"]
#
#    db = SQLite3::Database.new("db/store.db")
#    result=db.execute("SELECT id,pwd_digest FROM users WHERE user=?",user)
#
#    if result.empty?
#      redirect('/error')
#    end
#    
#    user_id = result.first["id"]
#    pwd_digest = result.first["pwd_digest"]
#
#    if BCrypt::Password.new(pwd_digest) == pwd
#      session[:user_id] = user_id
#      redirect('/welcome')
#    else
#      redirect('/error')
#    end
#  end