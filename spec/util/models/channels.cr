struct Kpbb::Channel
  def self.factory(
    handle : String = "channel-name",
    dname : String = "channel name",
    avatar : String? = nil,
    banner : String? = "",
    bio : String? = nil,
    creator_id : Int64 = 0_i64,
    public : Bool = true,
    listed : Bool = false
  ) : self
    self.save!(
      handle: handle,
      dname: dname,
      bio: bio,
      avatar: avatar,
      banner: banner,
      public: public,
      listed: listed,
      creator_id: creator_id)
  end
end

struct Kpbb::Webhook::Inbound::Endpoint
  def self.factory(
    creator_id : Int64,
    channel_id : Int64,
    uuid : UUID = UUID.random,
    secret : String = hashed_password,
    bio : String? = nil,
    data : String? = nil,
    default_body : String? = nil,
    active : Bool = true,
    mask : Kpbb::Mask::Mask = Kpbb::Mask::Mask::None,
    lastactive_at : Time? = nil,
    lastposted_at : Time? = nil,
    nextpost_at : Time? = nil,
    created_at : Time = Time.utc,
    updated_at : Time = Time.utc
  ) : self
    query = <<-SQL
      INSERT INTO #{@@table} (creator_id,
      channel_id, uuid, secret, bio, data, default_body, active, mask,
      lastactive_at, lastposted_at, nextpost_at, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      returning id
    SQL
    id = Kpbb.db.query_one(query, args: [
      creator_id,
      channel_id,
      uuid.to_s,
      secret,
      bio,
      data.presence,
      default_body.presence,
      active,
      mask.to_db_value,
      lastactive_at,
      lastposted_at,
      nextpost_at,
      created_at,
      updated_at,
    ], as: Int64)
    self.new(
      id,
      creator_id,
      channel_id,
      uuid,
      secret,
      bio,
      data.presence,
      default_body.presence,
      active,
      mask,
      lastactive_at,
      lastposted_at,
      nextpost_at,
      created_at,
      updated_at)
  end
end

struct Kpbb::Feed::Inbound::Endpoint
  def self.factory(
    creator_id : Int64,
    channel_id : Int64,
    url : String = "https://www.example.com/",
    bio : String? = nil,
    data : String? = nil,
    default_body : String? = nil,
    active : Bool = true,
    mask : Kpbb::Mask::Mask = Kpbb::Mask::Mask::None,
    frequency : Int16 = 0_i16,
    lastpolled_at : Time? = nil,
    nextpoll_at : Time? = nil,
    lastposted_at : Time? = nil,
    nextpost_at : Time? = nil,
    created_at : Time = Time.utc,
    updated_at : Time = Time.utc
  ) : self
    query = <<-SQL
      INSERT INTO #{@@table} (creator_id,
      channel_id, url, bio, data, default_body, active, mask,
      frequency, lastpolled_at, nextpoll_at, lastposted_at, nextpost_at, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      returning id
    SQL
    id = Kpbb.db.query_one(query, args: [
      creator_id,
      channel_id,
      url,
      bio,
      data.presence,
      default_body.presence,
      active,
      mask.to_db_value,
      frequency,
      lastpolled_at,
      nextpoll_at,
      lastposted_at,
      nextpost_at,
      created_at,
      updated_at,
    ], as: Int64)
    self.new(
      id,
      creator_id,
      channel_id,
      url,
      bio,
      data.presence,
      default_body.presence,
      active,
      mask,
      frequency,
      lastpolled_at,
      nextpoll_at,
      lastposted_at,
      nextpost_at,
      created_at,
      updated_at)
  end
end
