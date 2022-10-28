module Kpbb::Util::Model
  macro base62_title_url(prefix)
    def relative_title_url: String
      if title = @title
        return "#{{{ prefix }}}/#{Iom::WebSlug.slug(title)}-#{@id.to_base62}"
      end
      "#{{{ prefix }}}/#{@id.to_base62}"
    end
  end

  macro base62_title_url_not_nil(prefix)
    def relative_title_url: String
      if title = @title
        return "#{{{ prefix }}}/#{Iom::WebSlug.slug(title)}-#{@id.not_nil!.to_base62}"
      end
      "#{{{ prefix }}}/#{@id.not_nil!.to_base62}"
    end
  end

  macro base62_url(prefix)
    def relative_url: String
      "#{{{ prefix }}}/#{@id.to_base62}"
    end
  end

  macro base62_url_not_nil(prefix)
    def relative_url: String
      "#{{{ prefix }}}/#{@id.not_nil!.to_base62}"
    end
  end

  macro handle_url(prefix)
    def relative_url: String
      "#{{{ prefix }}}/#{@handle}"
    end
  end

  macro handle_url_not_nil(prefix)
    def relative_url: String
      "#{{{ prefix }}}/#{@handle.not_nil!}"
    end
  end
end
