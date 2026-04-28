require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions

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

  slim(:"purchase/purchase")
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

  slim(:'purchase/edit')
end

post('/purchase/:id/update') do
  id = params[:id].to_i
  name = params[:name]
  cost = params[:cost]

  update_purchase(name, cost, id, session[:user_id])

  redirect('/purchase')
end

post('/admin/purchase/:id/delete') do
  redirect('/purchase') unless session[:role] == 1
  admin_delete_purchase(params[:id].to_i)
  redirect('/admin')
end

get('/admin/purchase/:id/edit') do
  redirect('/purchase') unless session[:role] == 1
  @purchase = get_purchase(params[:id].to_i)
  slim(:'admin/admin_edit_purchase')
end

post('/admin/purchase/:id/update') do
  redirect('/purchase') unless session[:role] == 1
  admin_update_purchase(params[:name], params[:cost], params[:id].to_i)
  redirect('/admin')
end

post('/admin/users/:id/delete') do
  redirect('/purchase') unless session[:role] == 1
  admin_delete_user(params[:id].to_i)
  redirect('/admin')
end

get('/admin/users/:id/edit') do
  redirect('/purchase') unless session[:role] == 1
  @user = get_user(params[:id].to_i)
  slim(:'admin/admin_edit_user')
end

post('/admin/users/:id/update') do
  redirect('/purchase') unless session[:role] == 1
  admin_update_user(params[:name], params[:role].to_i, params[:id].to_i)
  redirect('/admin')
end

get('/users') do
  slim(:'user/register')
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
      session[:error_message] = "Lösenorden matchar inte"
      redirect('/error') #om lösenord it matchar
    end
  else
    redirect('/users') #om d redan finns
  end
  slim(:"user/register")
end

post('/login') do
  user = params["name"]
  pwd = params["pwd"]

  if get_login_attempts(user) >= 5
    session[:error_message] = "För många loginförsök"
    redirect('/error')
  end

  result = login_user(user)

  if result.nil?
    log_attempt(user, 0)
    session[:error_message] = "Okänd användare"
    redirect('/error')
  end
    
  if BCrypt::Password.new(result["pwd_digest"]) == pwd
    log_attempt(user, 1)
    session[:user_id] = result["id"]
    session[:role] = result["role"]
    redirect('/purchase')
  else
    log_attempt(user, 0)
    session[:error_message] = "Lösenord och användare matchar inte"
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
  @users = get_users
  
  @participants = {}
  @purchases.each do |purchase|
    @participants[purchase["id"]] = get_participants(purchase["id"])
  end

  slim(:'admin/admin')
end

post('/purchase/:id/pay') do
  id = params[:id].to_i
  pay_purchase(id, session[:user_id])
  redirect('/purchase')
end

get('/error') do
  @error_message = session[:error_message]
  slim(:error)
end

# SAKER O GÖRA

#- Yardoc
#- Mer validering, mer än bara eliasgrejen
#- Finslipa MVC
#- Finslipa namngivning enl restful, mappstruktur
#- CRUD admin