require "json"
require "kemal-session"

module Kemal
  class Session
    class PostgresEngine < Engine
      class StorageInstance
        macro define_storage(vars)
              include JSON::Serializable

              # JSON.mapping({
              #   {% for name, type in vars %}
              #     {{name.id}}s: Hash(String, {{type}}),
              #   {% end %}
              # })

              {% for name, type in vars %}
                @{{name.id}}s = Hash(String, {{type}}).new
                getter {{name.id}}s

                def {{name.id}}(k : String) : {{type}}
                  return @{{name.id}}s[k]
                end

                def {{name.id}}?(k : String) : {{type}}?
                  return @{{name.id}}s[k]?
                end

                def {{name.id}}(k : String, v : {{type}})
                  @{{name.id}}s[k] = v
                end

                def delete_{{name.id}}(k : String)
                  if @{{name.id}}s[k]?
                    @{{name.id}}s.delete(k)
                  end
                end
              {% end %}

              def initialize
                {% for name, type in vars %}
                  @{{name.id}}s = Hash(String, {{type}}).new
                {% end %}
              end
            end

        define_storage({
          int:    Int32,
          bigint: Int64,
          string: String,
          float:  Float64,
          bool:   Bool,
          object: Session::StorableObject::StorableObjectContainer,
        })
      end

      @cache : Hash(String, StorageInstance)
      @cached_session_read_times : Hash(String, Time)

      def initialize(@connection : DB::Database, @sessiontable : String = "sessions", @cachetime : Int32 = 5)
        # check if table exists, if not create it
        sql = "CREATE TABLE IF NOT EXISTS #{@sessiontable} (
            \"session_id\" varchar(36) NOT NULL,
            \"data\" text,
            \"updated_at\" timestamp DEFAULT NULL,
            PRIMARY KEY (\"session_id\")
          ); "
        @connection.exec(sql)
        @cache = {} of String => StorageInstance
        @cached_session_read_times = {} of String => Time
      end

      def run_gc
        # delete old sessions here
        expiretime = Time.local - Kemal::Session.config.timeout
        sql = "delete from #{@sessiontable} where updated_at < $1"
        @connection.exec(sql, expiretime)
        # delete old memory cache too, if it exists and is too old
        @cache.each do |session_id, session|
          if @cached_session_read_times[session_id]? && (Time.utc.to_unix - @cachetime) > @cached_session_read_times[session_id].to_unix
            @cache.delete(session_id)
            @cached_session_read_times.delete(session_id)
          end
        end
      end

      # def all_sessions : Array(StorageInstance)
      def all_sessions : Array(Kemal::Session)
        array = [] of StorageInstance
        sql = "select data from #{@sessiontable} "
        sessions = @connection.query_all(sql) do |rs|
          json = rs.read(String)
          StorageInstance.from_json(json)
        end
      end

      def create_session(session_id : String)
        session = StorageInstance.new
        data = session.to_json
        sql = "insert into #{@sessiontable} (session_id,data,updated_at) values($1,$2,NOW()) on conflict (session_id) do update set data = excluded.data, updated_at = excluded.updated_at"
        @connection.exec(sql, session_id, data)
        return session
      end

      def save_cache(session_id)
        data = @cache[session_id].to_json
        sql = "update #{@sessiontable} set data=$1,updated_at=NOW() where session_id = $2 "
        res = @connection.exec(sql, data, session_id)
      end

      def each_session
        sql = "select data from #{@sessiontable} "
        @connection.query_each(sql) do |rs|
          json = rs.read(String)
          yield StorageInstance.from_json(json)
        end
      end

      def get_session(session_id : String) : (Kemal::Session | Nil)
        return Session.new(session_id) if session_exists?(session_id)
      end

      def session_exists?(session_id : String) : Bool
        sql = "select session_id from #{@sessiontable} where session_id = $1"
        begin
          @connection.scalar(sql, session_id)
          return true
        rescue
          return false
        end
      end

      def destroy_session(session_id : String)
        sql = "delete from #{@sessiontable} where session_id = $1"
        @connection.exec(sql, session_id)
      end

      def destroy_all_sessions
        @connection.exec("truncate table #{@sessiontable}")
      end

      def load_into_cache(session_id : String) : StorageInstance
        begin
          json = @connection.query_one "select data from #{@sessiontable} where session_id = $1", session_id, &.read(String)
          @cache[session_id] = StorageInstance.from_json(json.to_s)
        rescue ex
          # recreates session based on id, if it has been deleted?
          @cache[session_id] = create_session(session_id)
        end
        @cached_session_read_times[session_id] = Time.utc
        @connection.exec("update #{@sessiontable} set updated_at = NOW() where session_id = $1", session_id)
        @cache[session_id]
      end

      def is_in_cache?(session_id : String) : Bool
        # only read from db once ever 'n' seconds. This should help with a single webpage hitting the db for every asset
        return false if !@cached_session_read_times[session_id]? # if not in cache reload it
        not_too_old = (Time.utc.to_unix - @cachetime) <= @cached_session_read_times[session_id].to_unix
        return not_too_old # if it is too old, load_into_cache will get called and it'll be reloaded
      end

      macro define_delegators(vars)
          {% for name, type in vars %}
            def {{name.id}}(session_id : String, k : String) : {{type}}
              load_into_cache(session_id) unless is_in_cache?(session_id)
              return @cache[session_id].{{name.id}}(k)
            end

            def {{name.id}}?(session_id : String, k : String) : {{type}}?
              load_into_cache(session_id) unless is_in_cache?(session_id)
              return @cache[session_id].{{name.id}}?(k)
            end

            def {{name.id}}(session_id : String, k : String, v : {{type}})
              load_into_cache(session_id) unless is_in_cache?(session_id)
              @cache[session_id].{{name.id}}(k, v)
              save_cache(session_id)
            end

            def {{name.id}}s(session_id : String) : Hash(String, {{type}})
              load_into_cache(session_id) unless is_in_cache?(session_id)
              return @cache[session_id].{{name.id}}s
            end

            def delete_{{name.id}}(session_id : String, k : String)
              load_into_cache(session_id) unless is_in_cache?(session_id)
              @cache[session_id].delete_{{name.id}}(k)
              save_cache(session_id)
            end
          {% end %}
        end

      define_delegators({
        int:    Int32,
        bigint: Int64,
        string: String,
        float:  Float64,
        bool:   Bool,
        object: Session::StorableObject::StorableObjectContainer,
      })
    end
  end
end
