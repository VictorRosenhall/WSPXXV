def db
  if @db.nil?
    @db = SQLite3::Database.new("db/databas.db")
    @db.results_as_hash = true
  end
  return @db
end

def add_participant(purchase_id, user_id, amount)
  db.execute("INSERT INTO USER_PURCHASE_REL (p_id, u_id, status, amount) VALUES (?, ?, ?, ?)",
             [purchase_id, user_id, "unpaid", amount])
end

def delete_purchase(id, user_id)
  db.execute("DELETE FROM purchase WHERE id = ? AND user_id = ?", [id, user_id])
end

def get_users
  db.execute("SELECT id, name FROM USERS")
end

def get_purchases(user_id)
  db.execute("SELECT purchase.* FROM purchase
    JOIN USER_PURCHASE_REL ON purchase.id = USER_PURCHASE_REL.p_id
    WHERE USER_PURCHASE_REL.u_id = ?", [user_id])
end

def search_purchases(user_id, query)
  db.execute("SELECT purchase.* FROM purchase
    JOIN USER_PURCHASE_REL ON purchase.id = USER_PURCHASE_REL.p_id
    WHERE USER_PURCHASE_REL.u_id = ? AND purchase.name LIKE ?", [user_id, "%#{query}%"])
end

def get_participants(purchase_id)
  db.execute("SELECT USERS.name, USER_PURCHASE_REL.status, USER_PURCHASE_REL.amount, USER_PURCHASE_REL.u_id
    FROM USER_PURCHASE_REL
    JOIN USERS ON USER_PURCHASE_REL.u_id = USERS.id
    WHERE USER_PURCHASE_REL.p_id = ?", [purchase_id])
end

def create_purchase(name, cost, user_id, category_id)
  db.execute("INSERT INTO purchase (name, cost, user_id, category_id) VALUES (?, ?, ?, ?)", [name, cost, user_id, category_id])
  db.last_insert_row_id
end

def get_purchase(id)
  db.execute("SELECT * FROM purchase WHERE id = ?", [id]).first
end

def update_purchase(name, cost, id, user_id)
  db.execute("UPDATE purchase SET name=?, cost=? WHERE id=? AND user_id=?", [name, cost, id, user_id])
end

def admin_delete_purchase(id)
  db.execute("DELETE FROM purchase WHERE id = ?", [id])
end

def admin_update_purchase(name, cost, id)
  db.execute("UPDATE purchase SET name=?, cost=? WHERE id=?", [name, cost, id])
end

def get_all_users
  db.execute("SELECT id, name, role FROM USERS")
end

def admin_delete_user(id)
  db.execute("DELETE FROM USERS WHERE id = ?", [id])
end

def admin_update_user(name, role, id)
  db.execute("UPDATE USERS SET name=?, role=? WHERE id=?", [name, role, id])
end

def get_user(id)
  db.execute("SELECT id, name, role FROM USERS WHERE id=?", [id]).first
end

def create_user(name, pwd_digest)
  db.execute("INSERT INTO USERS(name, pwd_digest) VALUES(?,?)", [name, pwd_digest])
end

def find_user(name)
  db.execute("SELECT id FROM USERS WHERE name=?", [name])
end

def login_user(name)
  db.execute("SELECT id, pwd_digest, role FROM USERS WHERE name=?", [name]).first
end

def pay_purchase(id, user_id)
  db.execute("UPDATE USER_PURCHASE_REL SET status = 'paid' WHERE p_id = ? AND u_id = ?", [id, user_id])
end

def get_all_purchases
  db.execute("SELECT purchase.*, USERS.name AS username FROM purchase
    JOIN USERS ON purchase.user_id = USERS.id")
end

def get_login_attempts(name)
  db.execute("SELECT COUNT(*) AS cnt FROM LOGIN_ATTEMPTS WHERE name = ? AND success = 0 AND time > ?", [name, Time.now.to_i - 300]).first["cnt"]
end

def log_attempt(name, success)
  db.execute("INSERT INTO LOGIN_ATTEMPTS (name, time, success) VALUES (?, ?, ?)", [name, Time.now.to_i, success])
end