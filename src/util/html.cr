module HTML
  @[AlwaysInline]
  def self.escape(string : Nil) : Nil
    nil
  end

  @[AlwaysInline]
  def self.escape(string : URI) : String
    self.escape string.to_s
  end
end
