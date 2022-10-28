# these values, when passed in via urlencodedform/json
# should be interpreted as explicitly true or false
# where there is likely explicit default behavior
# for when neither is specified

module Kpbb::Util::InputTruthyOrFalsy
  def truthy?(name : String) : Bool
    value = self[name]?
    return true if value == "1"
    return true if value == "true"
    return true if value == "y"
    return true if value == "yes"
    return true if value == "t"
    false
  end

  def falsey?(name : String) : Bool
    value = self[name]?
    return true if value == "0"
    return true if value == "false"
    return true if value == "n"
    return true if value == "no"
    return true if value == "f"
    false
  end

  def truthy_or_nil?(name : String) : Bool
    value = self[name]?
    return true if value.nil?
    return self.truthy? name
  end

  def falsey_or_nil?(name : String) : Bool
    value = self[name]?
    return true if value.nil?
    return self.falsey? name
  end
end

struct HTTP::Params
  include Kpbb::Util::InputTruthyOrFalsy
end

class Hash
  include Kpbb::Util::InputTruthyOrFalsy
end

# class String
# end

# class Nil
#   def truthy? : Bool
#     false
#   end
#   def falsey? : Bool
#     false
#   end

#   def truthy_or_nil? : Bool
#     return true
#   end

#   def falsey_or_nil? : Bool
#     return true
#   end
# end
