module Kpbb::Util::Model
  # @@table : String

  macro select
    @@select : String? = nil
    def self.select : String
      if @@select.nil?
        list = Array(String).new
        self.select_columns.each do |c|
          if c.starts_with? "#{@@table}."
            list << c
          elsif c.starts_with? "COALESCE"
            list << c
          else
            list << "#{@@table}.#{c}"
          end
        end
        @@select = list.join(", ")
      end
      @@select.not_nil!
    end

    @@select : String? = nil
    def self.select(prefix : String) : String
      list = Array(String).new
      self.select_columns.each do |c|
        if c.starts_with? "#{prefix}."
          list << c
        elsif c.starts_with? "COALESCE"
          list << c.gsub(@@table, prefix)
        else
          list << "#{prefix}.#{c}"
        end
      end
      select_value = list.join(", ")
    end

    def self.all() : Array(self)
      query = "SELECT #{self.select} FROM #{@@table} ORDER BY id ASC"
      list = Array(self).new

      Kpbb.db.query(query) do |rs|
        rs.each { list << self.new(rs) }
      end
      list
    end
  end

  macro find_by_bigint_id
    def self.find!(id : Int64) : self
      rs = Kpbb.db.query_one(<<-SQL,
        SELECT #{self.select} FROM #{@@table}
        WHERE id = $1 LIMIT 1
      SQL
      args: [
        id,
      ]) do |rs|
        return self.new(rs)
      end
    end

    def self.find?(id : Int64?) : self?
      return nil if id.nil?
      begin
        rs = Kpbb.db.query_one(<<-SQL,
          SELECT #{self.select} FROM #{@@table}
          WHERE id = $1 LIMIT 1
        SQL
        args: [
          id,
        ]) do |rs|
          return self.new(rs)
        end
      rescue ex : DB::NoResultsError
        nil
      end
      nil
    end

    def self.find(id_list : Array(Int64)) : Array(self)
      list = Array(self).new
      if id_list.size > 0
        nqm = NextQuestionMark.new
        query = <<-SQL
          SELECT #{self.select} FROM #{@@table}
          WHERE #{@@table}.id IN (#{(id_list.map { |v| nqm.next }).join(", ")})
        SQL
        rs = Kpbb.db.query(query, args: id_list) do |rs|
          rs.each {list << self.new(rs) }
        end
      end
      list
    end

    def self.last? : self?
      begin
        query = <<-SQL
          SELECT #{self.select} FROM #{@@table}
          ORDER BY id DESC LIMIT 1
        SQL
        rs = Kpbb.db.query_one(query) do |rs|
          return self.new(rs)
        end
      rescue ex : DB::NoResultsError
        nil
      end
      nil
    end
  end

  macro find_by_string_key(keyname)
    def self.find_by_{{keyname}}!(key : String) : self
      begin
        query = <<-SQL
          SELECT #{self.select} FROM #{@@table}
          WHERE "{{keyname}}" = $1 LIMIT 1
        SQL
        rs = Kpbb.db.query_one(query, args: [key]) do |rs|
          return self.new(rs)
        end
      end
    end

    def self.find_by_{{keyname}}?(key : String?) : self?
      return nil if key.nil?
      begin
        query = <<-SQL
          SELECT #{self.select} FROM #{@@table}
          WHERE "{{keyname}}" = $1 LIMIT 1
        SQL
        # puts query
        rs = Kpbb.db.query_one(query, args: [key]) do |rs|
          return self.new(rs)
        end
      rescue ex : DB::NoResultsError
        nil
      end
      nil
    end

    def self.find_by_{{keyname}}(key_list : Array(String)) : Array(self)
      list = Array(self).new
      if key_list.size > 0
        nqm = NextQuestionMark.new
        query = <<-SQL
          SELECT #{self.select} FROM #{@@table}
          WHERE #{@@table}."{{keyname}}" IN (#{(key_list.map { |v| nqm.next }).join(", ")})
        SQL
        rs = Kpbb.db.query(query, args: key_list) do |rs|
          rs.each {list << self.new(rs) }
        end
      end
      list
    end
  end

  macro find_by_uuid(keyname = "uuid")
    def self.find_by_uuid!(key : UUID) : self?
      find_by_uuid! key.to_s
    end

    def self.find_by_uuid!(key : String) : self
      begin
        query = <<-SQL
          SELECT #{self.select} FROM #{@@table}
          WHERE {{keyname}} = $1 LIMIT 1
        SQL
        rs = Kpbb.db.query_one(query, args: [key.to_s]) do |rs|
          return self.new(rs)
        end
      end
    end

    def self.find_by_uuid?(key : UUID) : self?
      find_by_uuid? key.to_s
    end

    def self.find_by_uuid?(key : String | Nil) : self?
      return nil if key.nil?
      begin
        query = <<-SQL
          SELECT #{self.select} FROM #{@@table}
          WHERE {{keyname}} = $1 LIMIT 1
        SQL
        # puts query
        rs = Kpbb.db.query_one(query, args: [key.try(&.to_s)]) do |rs|
          return self.new(rs)
        end
      rescue ex : DB::NoResultsError
        nil
      end
      nil
    end

    def self.find_by_uuid(key_list : Array(String)) : Array(self)
      list = Array(self).new
      if key_list.size > 0
        nqm = NextQuestionMark.new
        query = <<-SQL
          SELECT #{self.select} FROM #{@@table}
          WHERE #{@@table}.{{keyname}} IN (#{(key_list.map { |v| nqm.next }).join(", ")})
        SQL
        rs = Kpbb.db.query(query, args: key_list) do |rs|
          rs.each {list << self.new(rs) }
        end
      end
      list
    end
  end

  macro find_by_bigint_id_via_foreignkey(namesuffix, table, foreign_id)
    def self.find_by_{{namesuffix}}!(id : Int64) : self
      begin
        rs = Kpbb.db.query_one(<<-SQL,
          SELECT #{self.select} FROM #{@@table}
          WHERE id = (
            SELECT {{table}}.{{foreign_id}}
            FROM {{table}} WHERE id = $1
            LIMIT 1
          ) LIMIT 1
        SQL
        args: [
          id,
        ]) do |rs|
          return self.new(rs)
        end
      end
    end

    def self.find_by_{{namesuffix}}?(id : Int64) : self?
      begin
        rs = Kpbb.db.query_one(<<-SQL,
          SELECT #{self.select} FROM #{@@table}
          WHERE id = (
            SELECT {{table}}.{{foreign_id}}
            FROM {{table}} WHERE id = $1
            LIMIT 1
          ) LIMIT 1
        SQL
        args: [
          id,
        ]) do |rs|
          return self.new(rs)
        end
      rescue ex : DB::NoResultsError
        nil
      end
      nil
    end
  end

  macro find_by_http_env(model_id_key)
    # def self.find!(env : HTTP::Server::Context) : self
    #   return self.find! env.params.url["#{{{model_id_key}}}"].to_i64
    # end

    # def self.find?(env : HTTP::Server::Context) : self | Nil
    #   return self.find? env.params.url["#{{{model_id_key}}}"].to_i64
    # end

    def self.find!(env : HTTP::Server::Context) : self
      if input = env.params.url["#{{{model_id_key}}}"]?.try(&.to_i64_from_slug_prefixed_b62?)
        self.find! input
      else
        self.find! (nil || 0_i64)
      end
    end

    def self.find?(env : HTTP::Server::Context) : self | Nil
      if input = env.params.url["#{{{model_id_key}}}"]?.try(&.to_i64_from_slug_prefixed_b62?)
        self.find? input
      else
        self.find? nil
      end
    end

    def self.find_by_base62!(env : HTTP::Server::Context) : self
      if input = env.params.url["#{{{model_id_key}}}"]?.try(&.to_i64_from_b62?)
        self.find! input
      else
        self.find! (nil || 0_i64)
      end
    end

    def self.find_by_base62?(env : HTTP::Server::Context) : self | Nil
      if input = env.params.url["#{{{model_id_key}}}"]?.try(&.to_i64_from_b62?)
        self.find? input
      else
        self.find? nil
      end
    end
  end

  macro find_by_http_env_string(model_string_key)
    def self.find_by_{{model_string_key}}!(env : HTTP::Server::Context) : self
      return self.find_by_{{model_string_key}}! env.params.url["{{model_string_key}}"]
    end

    def self.find_by_{{model_string_key}}?(env : HTTP::Server::Context) : self | Nil
      return self.find_by_{{model_string_key}}? env.params.url["{{model_string_key}}"]
    end
  end

  macro find_by_dual_bigints_http_env_string(key_a, key_b)
    def self.find?(env : HTTP::Server::Context) : self | Nil
      key_a_s = env.params.url[{{key_b}}]?
      key_b_s = env.params.url[{{key_b}}]?
      if key_a_s && key_b_s
        key_a = Iom::Base62.decode(key_a_s).try(&.to_i64)
        key_b = Iom::Base62.decode(key_b_s).try(&.to_i64)
        if key_a_s && key_b_s
          return self.find?(key_a, key_b)
        end
      end
      nil
    end
    def self.find(env : HTTP::Server::Context) : self
      key_a_s = env.params.url[{{key_b}}]?
      key_b_s = env.params.url[{{key_b}}]?
      if key_a_s && key_b_s
        key_a = Iom::Base62.decode(key_a_s).try(&.to_i64)
        key_b = Iom::Base62.decode(key_b_s).try(&.to_i64)
        if key_a_s && key_b_s
          return self.find!(key_a, key_b)
        end
      end
      return self.find!(nil, nil)
    end
  end

  macro find_by_dual_bigints(key_a, key_b)
    def self.find!({{key_a}} : Int64, {{key_b}} : Int64) : self
      begin
        rs = Kpbb.db.query_one(<<-SQL,
          SELECT #{self.select} FROM #{@@table}
          WHERE {{key_a}} = $1 AND {{key_b}} = $2 LIMIT 1
        SQL
        args: [
          {{key_a}},
          {{key_b}},
        ]) do |rs|
          return self.new(rs)
        end
      end
    end

    def self.find?({{key_a}} : Int64, {{key_b}} : Int64) : self?
      begin
        rs = Kpbb.db.query_one(<<-SQL,
          SELECT #{self.select} FROM #{@@table}
          WHERE {{key_a}} = $1 AND {{key_b}} = $2 LIMIT 1
        SQL
        args: [
          {{key_a}},
          {{key_b}},
        ]) do |rs|
          value = self.new(rs)
          return value
        end
      rescue ex : DB::NoResultsError
        nil
      end
      nil
    end
  end
end
