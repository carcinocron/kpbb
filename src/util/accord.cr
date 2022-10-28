require "accord"
require "json"
require "../validator/**"

# monkey patch
module Accord
  def errorshash : Hash(Symbol, Array(String))
    hash = Hash(Symbol, Array(String)).new
    self.errors.each do |error|
      hash[error.attr] = Array(String).new unless hash.has_key? error.attr
      hash[error.attr] << error.message
    end
    hash
  end
  def errorshashstring : Hash(String, Array(String))
    hash = Hash(String, Array(String)).new
    self.errors.each do |error|
      attr = error.attr.to_s
      hash[attr] = Array(String).new unless hash.has_key? attr
      hash[attr] << error.message
    end
    hash
  end

  def to_json
    if self.errors.any?
      return {"message" => "Failed Validation", "errors" => self.errorshash }.to_json
    end
    ""
  end
end