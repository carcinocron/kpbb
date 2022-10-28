module Kpbb::View
  struct UserFromSession
    getter id : Int64?
    getter handle : String?

    def initialize(@id, @handle)
    end
  end

  class Context
    getter! user : UserFromSession
    errors : FlashErrors?
    old : FlashOld?
    getter env : HTTP::Server::Context
    getter now : Time
    property meta_description : String = ENV["APP_META_DESCRIPTION"]? || ENV["APP_NAME"]
    property window_title : String = ENV["APP_NAME"]

    def initialize(request : HTTP::Request, user, @now = Time.utc)
      response = HTTP::Server::Response.new(IO::Memory.new)
      @env = HTTP::Server::Context.new(request, response)
      @user = UserFromSession.new(user.id, user.handle)
      @now = Time.utc
    end

    def initialize(@env : HTTP::Server::Context)
      @user = UserFromSession.new(
        @env.session.bigint?("userId"),
        @env.session.string?("handle"))
      @now = Time.utc
    end

    def errors : FlashErrors
      if @errors.nil?
        @errors = @env.session.pull_object?("fe").try(&.as(FlashErrors?)) || FlashErrors.new
      end
      @errors.not_nil!
    end

    def old : FlashOld
      if @old.nil?
        @old = @env.session.pull_object?("fo").try(&.as(FlashOld?)) || FlashOld.new
      end
      @old.not_nil!
    end

    def old(key : String, default_value : String? = nil) : String?
      (old.has_key? key) ? old[key] : default_value
    end

    def path : String
      @env.not_nil!.request.path
    end

    def path_with_query : String
      @env.not_nil!.request.path_with_query
    end

    def admin? : Bool
      @env.session.can.admin?
    end

    def has_theme : Bool
      if t = @env.session.int?("t")
        return Kpbb::Themes.map_by_id.has_key?(t)
      end
      false
    end

    def theme : Kpbb::Themes::Theme
      Kpbb::Themes.map_by_id[@env.session.int?("t") || 0]
    end

    def base_url : String
      BASE_URL
    end

    def is_debug? : Bool
      ENV["APP_DEBUG"]? == "true"
    end
  end
end
