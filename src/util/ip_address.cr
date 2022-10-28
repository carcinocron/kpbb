class HTTP::Request
  def ip_address?
    if value = self.headers[CF_CONNECTING_IP]?
      return value
    end

    value = self.remote_address.try(&.to_s) || ""
    return nil if value == ""

    # remove port
    lastcolonindex = value.rindex(":")
    if lastcolonindex && lastcolonindex > 0
      value = value[0, lastcolonindex]
    end
    value
  end

  def ip_address!
    value = self.ip_address?
    # puts "ip_address! #{value}"
    value.presence.not_nil!
  end

  @[AlwaysInline]
  def ip_id : Int64
    Kpbb::Ipaddress.cached_upsert_id(self.ip_address!)
  end

  def cfipcountry : String
    # cfipcountry = self.headers["cf-ipcountry"]?
    # cfipcountry.downcase unless cfipcountry.nil?
    # cfipcountry
    self.headers["cf-ipcountry"].downcase
  end

  @[AlwaysInline]
  def cc_i16 : Int16
    Iom::CountryCode.to_i16(self.cfipcountry)
  end
end

private CF_CONNECTING_IP = "CF-Connecting-IP"
