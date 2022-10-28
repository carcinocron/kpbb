require "json"

struct FlashErrors
  include JSON::Serializable
  include Kemal::Session::StorableObject

  property errors : Hash(String, Array(String))

  def initialize(@errors = Hash(String, Array(String)).new)
  end

  def any? : Bool
    @errors.any?
  end

  def form_group_class(key : String) : String
    if @errors.has_key? key
      "has-error"
    else
      ""
    end
  end

  def form_input_class(key : String) : String
    if @errors.has_key? key
      "is-invalid"
    else
      ""
    end
  end

  def form_group_p(key : String) : String
    if @errors.has_key? key
      "<div class=\"invalid-feedback\">" + (@errors[key].join " ") + "</div>"
    else
      ""
    end
  end
end

struct FlashOld
  alias Data = ::Hash(String, String | Int16 | Nil)

  include JSON::Serializable
  include Kemal::Session::StorableObject

  property data : Data

  # def initialize(data = typeof(@data).new)
  #   @data = data.compact
  # end

  def initialize(@data = typeof(@data).new)
  end

  def initialize(params : HTTP::Params)
    @data = typeof(@data).new
    params.each do |name, value|
      case name
      when "password", "password2", "current_password", "secret"
        # pass
      else
        @data[name] = value
      end
    end
  end

  def [](key : String) : String
    @data[key]?.to_s
  end

  def []?(key : String) : String?
    case v = @data[key]?
    when String
      v.presence
    when Int
      v.to_s
    else
      nil
    end
  end

  def has_key?(key : String) : Bool
    @data.has_key? key
  end
end
