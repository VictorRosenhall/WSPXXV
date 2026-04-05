require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions

DB_FILE = "db/databas.db" #används inte längre? ta bort?

get('/') do
  slim(:index)
end

get('/purchase') do
  redirect('/users') unless session[:user_id]

  @users = get_users
  query = params[:q]

  if query && !query.strip.empty?
    @purchase =  search_purchases(session[:user_id], query)
      else
    @purchase = get_purchases(session[:user_id])
      end
  
    @participants = {}
    
    @purchase.each do |p|
      @participants[p["id"]] = get_participants(p["id"])
    end

  slim(:purchase)
end

post('/purchase') do

  name = params[:name]
  cost = params[:cost]

  id = create_purchase(name, cost, session[:user_id], params[:category_id])

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

  delete_purchase(id, session[:user_id])

  redirect('/purchase')
end

get('/purchase/:id/edit') do
  redirect('/users') unless session[:user_id]
  id = params[:id].to_i

  @purchase = get_purchase(id)

  slim(:edit)
end

post('/purchase/:id/update') do
  id = params[:id].to_i
  name = params[:name]
  cost = params[:cost]

  update_purchase(name, cost, id, session[:user_id])

  redirect('/purchase')
end

get('/users') do
  slim(:register)
end

post('/users') do
  user = params["name"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]

  result = find_user(user)

  if result.empty?
    if pwd == pwd_confirm
      pwd_digest = BCrypt::Password.create(pwd)
      create_user(user, pwd_digest)
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

  if get_login_attempts(user) >= 5
    redirect('/error')
  end

  result = login_user(user)

  if result.nil?
    log_attempt(user, 0)
    redirect('/error')
  end
    
  if BCrypt::Password.new(result["pwd_digest"]) == pwd
    log_attempt(user, 1)
    session[:user_id] = result["id"]
    session[:role] = result["role"]
    redirect('/purchase')
  else
    log_attempt(user, 0)
    redirect('/error')
  end
end

get('/logout') do
  session.clear
  redirect('/users')
end

get('/admin') do
  redirect('/purchase') unless session[:role] == 1

  @purchases = get_all_purchases
  
  @participants = {}
  @purchases.each do |purchase|
    @participants[purchase["id"]] = get_participants(purchase["id"])
  end

  slim(:admin)
end

post('/purchase/:id/pay') do
  id = params[:id].to_i
  pay_purchase(id, session[:user_id])
  redirect('/purchase')
end

get('/error') do
  slim(:error)
end