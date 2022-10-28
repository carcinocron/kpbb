class Hash
  def presence : self?
    self.size > 0 ? self : nil
  end
end

# Kpbb::BodyHash
module Kpbb
  alias BodyHash = Hash(String, String)
  alias JsonHash = Hash(String, String | Int64 | Nil)
end
