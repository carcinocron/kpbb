require "iom-encrypt"

@[Kpbb::Orm::Table(from: "emails")]
struct Kpbb::Email
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_bigint_id
  Kpbb::Util::Model.find_by_bigint_id_via_foreignkey(userpw_id, users, pw_id)
  # Kpbb::Util::Model.find_by_http_env("email_id")
  @@table = "emails"

  def self.select_columns : Array(String)
    ["id", "user_id", "data", "hash", "verified", "recovery", "active", "created_at"]
  end

  @[Kpbb::Orm::Column(insert: false, insert_return: true)]
  property id : Int64
  property user_id : Int64
  property data : String
  property hash : Int16
  property verified : Bool
  property recovery : Bool
  property active : Bool
  property created_at : Time

  def initialize(
    @id : Int64,
    @user_id : Int64,
    @data : String,
    @hash : Int16,
    @verified : Bool,
    @recovery : Bool,
    @active : Bool,
    @created_at : Time
  )
  end

  def email : String
    self.data.email
  end

  def self.partial_mask(email : String) : String
    # r = Random.new(Digest::CRC32.checksum email)

    # no point in censoring an invalid email address
    begin
      at : Int32 = (email.rindex "@").not_nil!
      dot : Int32 = (email.rindex ".").not_nil!
    rescue
      return email
    end

    masked = Array(Char).new
    email.each_char_with_index do |char, index|
      case index
      when nil
        # pass
      when 0, 1
        masked << char
      when at - 1, at - 2, at, at + 1, at + 2
        masked << char
      when index > at
        masked << char
      when dot - 1, dot - 2, dot
        masked << char
      when index > dot
        masked << char
      else
        if (index < dot) && (char == '@' || char == '.' || char == '+')
          masked << char
        else
          masked << '*'
        end
      end
    end
    # if at > 3
    #   "#{email[0]}#{"*" * at-2}#{email[0]}@something.com"
    # else
    #   email
    # end
    return masked.join ""
  end

  @[AlwaysInline]
  def partial_mask : String
    Kpbb::Email.partial_mask(email: self.email)
  end

  def crc32 : String
    self.data.crc32
  end

  def encrypted_user_id : Int64
    self.data.user_id
  end

  def data : Kpbb::Email::Data
    vn = Iom::Encrypt::EncryptedValue.from_base64_json @data
    Kpbb::Email::Data.from_encrypted(vn)
  end

  def initialize(rs : DB::ResultSet)
    @id = rs.read(Int64)
    @user_id = rs.read(Int64)
    data = rs.read(JSON::Any?)
    @data = (data ? data.to_json : nil).not_nil!
    @hash = rs.read(Int16)
    @verified = rs.read(Bool)
    @recovery = rs.read(Bool)
    @active = rs.read(Bool)
    @created_at = rs.read(Time)
  end

  def self.save!(user_id : Int64, email : String, recovery : Bool = false, connection : DB::Connection? = nil) : self
    connection ||= Kpbb.db
    data = Kpbb::Email::Data.new(email, user_id)
    hash : Int16 = (data.crc32 % UInt16::MAX).to_u16.unsafe_as(Int16)
    data_s : String = data.to_encrypted.to_base64_json
    query = <<-SQL
      INSERT INTO #{@@table} (user_id, data, hash, verified, recovery, active, created_at)
      VALUES ($1, $2, $3, $4, $5, true, NOW())
      returning id, created_at, verified, recovery, active
    SQL
    id, created_at, verified, active = connection.query_one(query, args: [
      user_id,
      data_s,
      hash,
      verified = false,
      recovery,
    ], as: {Int64, Time, Bool, Bool})
    self.new(id, user_id, data_s, hash, verified, recovery, active, created_at)
  end

  def self.all(connection : DB::Connection? = nil) : Array(self)
    connection ||= Kpbb.db
    list = Array(self).new
    bindings = Array(::Kpbb::PGValue).new
    query = "SELECT #{self.select} from #{@@table} ORDER BY id ASC"
    connection.query(query, args: bindings) do |rs|
      rs.each { list << self.new(rs) }
    end
    list
  end

  def self.find(user_id : Int64, connection : DB::Connection? = nil) : Array(self)
    connection ||= Kpbb.db
    list = Array(self).new
    bindings = Array(::Kpbb::PGValue).new

    query = <<-SQL
      SELECT #{self.select} from #{@@table}
      WHERE user_id = $1
      AND active IS TRUE
      ORDER BY id ASC
    SQL
    bindings << user_id
    connection.query(query, args: bindings) do |rs|
      rs.each { list << self.new(rs) }
    end
    list
  end

  def self.find(user_id : Int64, email : String, connection : DB::Connection? = nil) : Array(self)
    connection ||= Kpbb.db
    list = Array(self).new
    bindings = Array(::Kpbb::PGValue).new

    hash : Int16 = (Digest::CRC32.checksum(email) % UInt16::MAX).to_u16.unsafe_as(Int16)

    query = <<-SQL
      SELECT #{self.select} from #{@@table}
      WHERE user_id = $1
      AND hash = $2
      AND active IS TRUE
      ORDER BY id ASC
    SQL
    bindings << user_id
    bindings << hash
    connection.query(query, args: bindings) do |rs|
      rs.each { list << self.new(rs) }
    end
    list
  end

  def self.find!(email_id : Int64, user_id : Int64) : self
    query = <<-SQL
      SELECT #{self.select} FROM #{@@table}
      WHERE id = $1
      WHERE user_id = $2
      AND active IS TRUE
      LIMIT 1
    SQL
    rs = Kpbb.db.query_one(query, args: [
      email_id,
      user_id,
    ]) do |rs|
      return self.new(rs)
    end
  end
end

# @todo
# @link https://forum.crystal-lang.org/t/simple-encrypt-decrypt/2354
struct Kpbb::Email::Data
  include JSON::Serializable

  property email : String
  property user_id : Int64
  property crc32 : UInt32

  def initialize(@email : String, @user_id : Int64)
    @crc32 = Digest::CRC32.checksum(@email.downcase)
  end

  def self.from_encrypted(value : String) : self
    ev = Iom::Encrypt::EncryptedValue.from_json value
    e = Iom::Encrypt::Encrypter.new ENV["APP_KEY"]
    self.from_json e.decrypt ev
  end

  def self.from_encrypted(ev : Iom::Encrypt::EncryptedValue) : self
    e = Iom::Encrypt::Encrypter.new ENV["APP_KEY"]
    self.from_json e.decrypt ev
  end

  def to_encrypted : Iom::Encrypt::EncryptedValue
    e = Iom::Encrypt::Encrypter.new ENV["APP_KEY"]
    e.encrypt(self.to_json)
  end
end
