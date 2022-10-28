struct Int
  @[AlwaysInline]
  def to_b62? : String?
    Iom::Base62.encode(self)
  end

  @[AlwaysInline]
  def to_b62 : String
    Iom::Base62.encode(self)
  end
end
