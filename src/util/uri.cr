class URI
  def append_query(key : String, value : String) : URI
    uri = self.dup
    query = HTTP::Params.parse(uri.query || "")
    query[key] = value
    uri.query = query.to_s
    return uri
  end

  def append_query(key : String, value : Nil) : URI
    uri = self.dup
    query = HTTP::Params.parse(uri.query || "")
    query.delete_all(key)
    uri.query = query.to_s
    return uri
  end

  def has_non_html_file_extension? : Bool
    if ext = self.extension
      return false if ext == "html"
      return false if ext == "html5"
      return false if ext == "htm"
      return true
    end
    return false
  end

  def extension : String?
    path = self.path
    if lastdot = path.rindex "."
      return path[lastdot + 1, 5].presence
    end
    return nil
  end

  def e : String
    ::HTML.escape(self)
  end
end
