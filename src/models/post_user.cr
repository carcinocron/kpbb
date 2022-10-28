@[Kpbb::Orm::Table(from: "postusers")]
struct Kpbb::PostUser
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_dual_bigints_http_env_string "post_id", "user_id"
  Kpbb::Util::Model.find_by_dual_bigints post_id, user_id
  @@table = "postusers"

  def self.select_columns : Array(String)
    ["id", "post_id", "user_id", "saved_at", "hidden_at"]
  end

  property id : Int64
  property post_id : Int64
  property user_id : Int64
  property saved_at : Time?
  property hidden_at : Time?

  def initialize(@id : Int64, @post_id : Int64, @user_id : Int64, @saved_at : Time? = nil, @hidden_at : Time? = nil)
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @post_id = rs.read(Int64)
    @user_id = rs.read(Int64)
    @saved_at = rs.read(Time?)
    @hidden_at = rs.read(Time?)
  end

  def saved : Bool
    !@saved_at.nil?
  end

  def hidden : Bool
    !@hidden_at.nil?
  end

  def self.save!(post_id : Int64, user_id : Int64, saved_at : Time? = nil, hidden_at : Time? = nil) : Int64
    id = Kpbb.db.query_one(<<-SQL,
      INSERT INTO #{@@table} (post_id, user_id, saved_at, hidden_at)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (post_id, user_id)
      DO UPDATE SET saved_at = excluded.saved_at, hidden_at = excluded.hidden_at
      returning id
    SQL


      args: [
        post_id,
        user_id,
        saved_at,
        hidden_at,
      ], as: Int64)
  end

  def self.find(page : Page(Kpbb::Post), user_id : Int64?)
    Array(self)
    post_id_list : Array(Int64) = page.collection.map { |c| c.id }
    self.find(post_id_list, user_id)
  end

  def self.find(posts : Array(Kpbb::Post), user_id : Int64?)
    Array(self)
    post_id_list : Array(Int64) = posts.map { |c| c.id }
    self.find(post_id_list, user_id)
  end

  def self.find(post_id_list : Array(Int64), user_id : Int64?)
    Array(self)
    list = Array(self).new
    if post_id_list.size > 0 && user_id
      nqm = NextQuestionMark.new
      bindings = Array(::Kpbb::PGValue).new(post_id_list.size) do |index|
        post_id_list[index]
      end
      bindings << user_id
      query = <<-SQL
        SELECT #{self.select} FROM #{@@table}
        WHERE post_id IN (#{(post_id_list.map { |p| nqm.next }).join(", ")})
        AND user_id = #{nqm.next}
      SQL
      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { list << self.new(rs) }
      end
    end
    list
  end
end
