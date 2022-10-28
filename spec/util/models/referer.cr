struct Kpbb::Referer
  def self.factory(
    value : String = "https://www.google.com/",
    lastseen_at : Time = Time.utc
  ) : self
    id, created_at = Kpbb.db.query_one(<<-SQL,
      INSERT INTO referers (value, lastseen_at, created_at)
      VALUES ($1, $2, NOW())
      ON CONFLICT (value) DO UPDATE SET lastseen_at = excluded.lastseen_at
      returning id, created_at
    SQL
      args: [
        value,
        lastseen_at,
      ], as: {Int64, Time})
    self.find! id
  end
end
