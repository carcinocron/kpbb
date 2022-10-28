@[Kpbb::Orm::Table(from: "appsettingskv")]
struct Kpbb::SettingKeyValue
  @@cache : self? = nil

  def self.cache : self
    @@cache ||= fetch
  end

  property data : ::Hash(String, String)

  def initialize(@data = ::Hash(String, String).new)
  end

  def self.data : ::Hash(String, String)
    cache.data
  end

  def self.fetch_skip_cache : self
    d = ::Hash(String, String).new
    Kpbb.db.query(FETCH_ALL) do |rs|
      rs.each {
        k = rs.read(String?)
        v = rs.read(String?)
        d[k] = v if (k && v)
      }
    end
    self.new d
  end

  @[AlwaysInline]
  def self.fresh : self
    @@cache = fetch_skip_cache
  end

  @[AlwaysInline]
  def self.fetch : self
    @@cache ||= fetch_skip_cache
  end

  @[AlwaysInline]
  def write(k : Symbol, v) : Nil
    write(k.to_s, v)
  end

  def write(k : String, v : String?) : Nil
    @data[k] = v
    Kpbb.db.exec(UPSERT, args: [k, v])
  end

  def write(k : String, v : Bool) : Nil
    write(k, v ? "1" : "0")
  end

  @[AlwaysInline]
  def [](key : String) : String
    @data[key]
  end

  @[AlwaysInline]
  def []?(key : String) : String?
    @data[key]?
  end

  @[AlwaysInline]
  def has_key?(key : String) : Bool
    @data.has_key? key
  end

  {% for setting in ([
                      {:key => :register_require_invitecode, :default => false},
                      {:key => :enable_nsfw, :default => false},
                      {:key => :enable_downvote, :default => false},
                      {:key => :enable_cron, :default => true},
                    ]) %}
    {% if setting[:default] == true %}
      def {{setting[:key].id}}? : Bool
        v = @data["{{setting[:key].id}}"]?
        !(v == "false" || v == "0")
      end
      def {{setting[:key].id}}= (new_value : Bool) : Nil
        write(:{{setting[:key].id}}, new_value)
      end
    {% end %}
    {% if setting[:default] == false %}
      def {{setting[:key].id}}? : Bool
        v = @data["{{setting[:key].id}}"]?
        !(v == "true" || v == "1")
      end
      def {{setting[:key].id}}= (new_value : Bool) : Nil
        write(:{{setting[:key].id}}, new_value)
      end
    {% end %}
  {% end %}
end

private FETCH_ALL = <<-SQL
  SELECT k, v FROM appsettingskv
SQL

private UPSERT = <<-SQL
  INSERT INTO appsettingskv (k, v)
  VALUES ($1, $2)
  ON CONFLICT (k) DO UPDATE
  SET v = excluded.v
SQL
