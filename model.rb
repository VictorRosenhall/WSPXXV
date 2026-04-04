def db
  return @db if @db
  @db = SQLite3::Database.new("db/databas.db")
  @db.results_as_hash = true
  return @db
end

def add_participant(purchase_id, user_id, amount)
  db.execute("INSERT INTO USER_PURCHASE_REL (p_id, u_id, status, amount) VALUES (?, ?, ?, ?)",
             [purchase_id, user_id, "unpaid", amount])
end