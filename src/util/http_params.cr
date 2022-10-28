struct HTTP::Params
  def self.from_hash(hash : Hash) : self
    params = HTTP::Params.new
    hash.each do |key, value|
      params[key.to_s] = value.to_s
    end
    return params
  end
end
