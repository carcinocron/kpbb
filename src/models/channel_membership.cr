@[Kpbb::Orm::Table(from: "channelmemberships")]
struct Kpbb::ChannelMembership
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_dual_bigints_http_env_string "user_id", "user_id"
  Kpbb::Util::Model.find_by_dual_bigints channel_id, user_id
  @@table = "channelmemberships"

  # def self.select_columns : Array(String)
  #   ["id", "channel_id", "user_id", "rank", "banned", "hidden", "follow"]
  # end

  @[Kpbb::Orm::Column(insert: false, insert_return: true)]
  property id : Int64
  @[Kpbb::Orm::Column(upsert_key: true)]
  property channel_id : Int64
  @[Kpbb::Orm::Column(upsert_key: true)]
  property user_id : Int64
  @[Kpbb::Orm::Column]
  property rank : Int16
  @[Kpbb::Orm::Column]
  property banned : Bool
  @[Kpbb::Orm::Column]
  property hidden_at : Time?
  @[Kpbb::Orm::Column]
  property follow : Bool
  @[Kpbb::Orm::Column(insert: "NOW()", insert_return: true)]
  property created_at : Time? = nil
  @[Kpbb::Orm::Column(insert: "NOW()", insert_return: true)]
  property updated_at : Time? = nil

  def initialize(@id : Int64, @channel_id : Int64, @user_id : Int64, @rank : Int16, @banned : Bool = false, @hidden_at : Time? = nil, @follow : Bool = false, created_at : Time? = nil, updated_at : Time? = nil)
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @channel_id = rs.read(Int64)
    @user_id = rs.read(Int64)
    @rank = rs.read(Int16)
    @banned = rs.read(Bool)
    @hidden_at = rs.read(Time?)
    @follow = rs.read(Bool)
    @created_at = rs.read(Time?)
    @updated_at = rs.read(Time?)
  end

  def hidden : Bool
    !@hidden_at.nil?
  end

  use_orm_upsert

  def self.save!(
    channel_id : Int64,
    user_id : Int64,
    rank : Int16 = 0,
    banned : Bool = false,
    hidden_at : Time? = nil,
    follow : Bool = false,
    connection : DB::Connection? = nil
  ) : self
    self.upsert!(channel_id: channel_id, user_id: user_id, rank: rank, banned: banned, hidden_at: hidden_at, follow: follow, connection: connection)
    connection ||= Kpbb.db

    query = <<-SQL
      INSERT INTO #{@@table} (channel_id, user_id, rank, banned, hidden_at, follow)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (channel_id, user_id) DO UPDATE
      SET rank = excluded.rank, banned = excluded.banned, hidden_at = excluded.hidden_at, follow = excluded.follow
      returning id
    SQL
    id = Kpbb.db.query_one(query, args: [
      channel_id,
      user_id,
      rank,
      banned,
      hidden_at,
      follow,
    ], as: Int64)
    self.new(id, channel_id, user_id, rank, banned, hidden_at, follow)
  end

  def fetch_rank(channel_id : Int64, user_id : Int64) : Int64
    membership = self.find(channel_id, user_id)
    membership ? membership.rank : 0
  end

  def self.find(page : Page(Kpbb::Channel), user_id : Int64?)
    Array(self)
    channel_id_list : Array(Int64) = page.collection.map { |c| c.id }
    self.find(channel_id_list, user_id)
  end

  def self.find(page : Page(Kpbb::Post), user_id : Int64?)
    Array(self)
    channel_id_list : Array(Int64) = page.collection.map { |c| c.channel_id }.uniq
    self.find(channel_id_list, user_id)
  end

  def self.find(channels : Array(Kpbb::Channel), user_id : Int64?)
    Array(self)
    channel_id_list : Array(Int64) = channels.map { |c| c.id }
    self.find(channel_id_list, user_id)
  end

  def self.find(channel_id_list : Array(Int64), user_id : Int64?)
    Array(self)
    list = Array(self).new
    if channel_id_list.size > 0 && user_id
      nqm = NextQuestionMark.new
      bindings = Array(::Kpbb::PGValue).new(channel_id_list.size) do |index|
        channel_id_list[index]
      end
      bindings << user_id
      query = <<-SQL
        SELECT #{self.select} FROM #{@@table}
        WHERE channel_id IN (#{(channel_id_list.map { |c| nqm.next }).join(", ")})
        AND user_id = #{nqm.next}
      SQL
      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { list << self.new(rs) }
      end
    end
    list
  end
end
