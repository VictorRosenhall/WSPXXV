def db
  return @db if @db
  @db = SQLite3::Database.new("db/databas.db")
  @db.results_as_hash = true
  return @db
end