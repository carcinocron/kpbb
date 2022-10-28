class String
  @[AlwaysInline]
  def to_i64_from_slug_prefixed_b62? : Int64?
    if last_dash_index = self.rindex '-'
      return Iom::Base62.decode(self[last_dash_index..]).to_i64
    end
    Iom::Base62.decode(self).to_i64
  end

  @[AlwaysInline]
  def to_i64_from_slug_prefixed_b62 : Int64
    self.to_i64_from_slug_prefixed_b62?.not_nil!
  end

  @[AlwaysInline]
  def to_i64_from_b62? : Int64?
    Iom::Base62.decode(self).to_i64
  end

  @[AlwaysInline]
  def to_i64_from_b62 : Int64
    Iom::Base62.decode(self).to_i64.not_nil!
  end

  @[AlwaysInline]
  def to_i32_from_b62? : Int32?
    Iom::Base62.decode(self).to_i64.to_i32
  end

  @[AlwaysInline]
  def to_i32_from_b62 : Int32
    Iom::Base62.decode(self).to_i64.not_nil!.to_i32.not_nil!
  end

  @[AlwaysInline]
  def to_i16_from_b62? : Int16?
    Iom::Base62.decode(self).to_i64.to_i16
  end

  @[AlwaysInline]
  def to_i16_from_b62 : Int16
    Iom::Base62.decode(self).to_i64.not_nil!.to_i16.not_nil!
  end

  def starts_with_http_or_https? : Bool
    starts_with?("http://") || starts_with?("https://")
  end

  @[AlwaysInline]
  def e : String
    ::HTML.escape(self)
  end
end
