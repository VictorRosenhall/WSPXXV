require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions

include Model

before '/purchase*' do
  redirect('/users') unless session[:user_id]
end

before '/admin*' do
  redirect('/purchase') unless session[:role] == 1
end

# @route GET /
# @return [slim] renderar startsidan
get('/') do
  slim(:index)
end

# @route GET /purchase
# @param [String] q sökterm för att filtrera köp (valfri)
# @return [slim] renderar purchase-vyn med köp och deltagare
# @note Kräver inloggning, redirectar till /users om ej inloggad
get('/purchase') do
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

# @route POST /purchase
# @param [String] name namn på köpet
# @param [Float] cost kostnad för köpet
# @param [Array] participants lista med user_ids att dela köpet med (valfri)
# @return [redirect] redirectar till /purchase
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

# @route POST /purchase/:id/delete
# @param [Integer] id köpets id
# @return [redirect] redirectar till /purchase
post('/purchase/:id/delete') do
  id = params[:id]

  delete_purchase(id, session[:user_id])

  redirect('/purchase')
end

# @route GET /purchase/:id/edit
# @param [Integer] id köpets id
# @return [slim] renderar edit-vyn
# @note Kräver inloggning
get('/purchase/:id/edit') do
  id = params[:id].to_i

  @purchase = get_purchase(id)

  slim(:'purchase/edit')
end

# @route POST /purchase/:id/update
# @param [Integer] id köpets id
# @param [String] name nytt namn
# @param [Float] cost ny kostnad
# @return [redirect] redirectar till /purchase
post('/purchase/:id/update') do
  id = params[:id].to_i
  name = params[:name]
  cost = params[:cost]

  update_purchase(name, cost, id, session[:user_id])

  redirect('/purchase')
end

# @route POST /admin/purchase/:id/delete
# @param [Integer] id köpets id
# @return [redirect] redirectar till /admin
# @note Kräver adminbehörighet
post('/admin/purchase/:id/delete') do
  admin_delete_purchase(params[:id].to_i)
  redirect('/admin')
end

# @route GET /admin/purchase/:id/edit
# @param [Integer] id köpets id
# @return [slim] renderar admin_edit_purchase-vyn
# @note Kräver adminbehörighet
get('/admin/purchase/:id/edit') do
  @purchase = get_purchase(params[:id].to_i)
  slim(:'admin/admin_edit_purchase')
end

# @route POST /admin/purchase/:id/update
# @param [Integer] id köpets id
# @param [String] name nytt namn
# @param [Float] cost ny kostnad
# @return [redirect] redirectar till /admin
# @note Kräver adminbehörighet
post('/admin/purchase/:id/update') do
  admin_update_purchase(params[:name], params[:cost], params[:id].to_i)
  redirect('/admin')
end

# @route POST /admin/users/:id/delete
# @param [Integer] id användarens id
# @return [redirect] redirectar till /admin
# @note Kräver adminbehörighet
post('/admin/users/:id/delete') do
  admin_delete_user(params[:id].to_i)
  redirect('/admin')
end

# @route GET /admin/users/:id/edit
# @param [Integer] id användarens id
# @return [slim] renderar admin_edit_user-vyn
# @note Kräver adminbehörighet
get('/admin/users/:id/edit') do
  @user = get_user(params[:id].to_i)
  slim(:'admin/admin_edit_user')
end

# @route POST /admin/users/:id/update
# @param [Integer] id användarens id
# @param [String] name nytt namn
# @param [Integer] role ny roll (1=admin, 0=användare)
# @return [redirect] redirectar till /admin
# @note Kräver adminbehörighet
post('/admin/users/:id/update') do
  admin_update_user(params[:name], params[:role].to_i, params[:id].to_i)
  redirect('/admin')
end

# @route GET /users
# @return [slim] renderar register-vyn med inloggning och registrering
get('/users') do
  slim(:'user/register')
end

# @route POST /users
# @param [String] name användarnamn
# @param [String] pwd lösenord
# @param [String] pwd_confirm lösenordsbekräftelse
# @return [redirect] redirectar till /users eller /error
post('/users') do
  user = params["name"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]

  result = find_user(user)

  if result.empty?
    if pwd == pwd_confirm
      create_user(user, pwd)
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

# @route POST /login
# @param [String] name användarnamn
# @param [String] pwd lösenord
# @return [redirect] redirectar till /purchase eller /error
# @note Loggar inloggningsförsök och blockerar efter 5 misslyckade försök inom 5 minuter
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
    
  if authenticate_user(result["pwd_digest"], pwd)
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

# @route GET /logout
# @return [redirect] rensar sessionen och redirectar till /users
get('/logout') do
  session.clear
  redirect('/users')
end

# @route GET /admin
# @return [slim] renderar admin-vyn med alla köp och användare
# @note Kräver adminbehörighet
get('/admin') do
  @purchases = get_all_purchases
  @users = get_users
  
  @participants = {}
  @purchases.each do |purchase|
    @participants[purchase["id"]] = get_participants(purchase["id"])
  end

  slim(:'admin/admin')
end

# @route POST /purchase/:id/pay
# @param [Integer] id köpets id
# @return [redirect] redirectar till /purchase
post('/purchase/:id/pay') do
  id = params[:id].to_i
  pay_purchase(id, session[:user_id])
  redirect('/purchase')
end

# @route GET /error
# @return [slim] renderar error-vyn med felmeddelande från sessionen
get('/error') do
  @error_message = session[:error_message]
  slim(:error)
end

# SAKER O GÖRA

#- Mer validering (mer än bara eliasgrejen?)
#- Finslipa MVC, (bcrypt -> modellen)
#- before block

# HAR GJORT

#- Restful
#- CRUD Admin
#- Cooldown