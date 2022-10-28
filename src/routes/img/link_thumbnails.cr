require "http/client"

private THUMBNAIL    = /^([a-zA-Z0-9]{1,8})\.(png|jpg)$/
private COPY_HEADERS = [
  "Content-Size",
  # "Content-Length",
  "Content-Type",
]

Kpbb::Thumbnail.list.each do |thumbnail|
  get "/img/l#{thumbnail.c}/:filename" do |env|
    filename = env.params.url["filename"]

    unless filename.ends_with?(".png") || filename.ends_with?(".jpg")
      env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
      halt_404
    end
    # halt_404 unless THUMBNAIL.matches? filename # only in 0.35
    unless md = THUMBNAIL.match filename
      env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
      halt_404
    end

    unless link_id = Iom::Base62.decode(md[1]).try(&.to_i64)
      env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
      halt_404
    end

    link = Kpbb::Link.find! link_id

    unless thumbnail_url = link.meta.unfurl.try(&.thumbnail)
      halt_404
    end

    url = ENV["IMAGICK_API"]
    form = HTTP::Params.build do |form|
      form.add "from_url", thumbnail_url
      form.add "action", "link_thumbnail"
      form.add "width", thumbnail.width.to_s
      form.add "height", thumbnail.height.to_s
    end
    res = HTTP::Client.post(url, form: form)

    # need to set headers first, otherwise they're already sent
    # env.response.headers.merge! Kpbb::Headers::PNG
    COPY_HEADERS.each do |name|
      if res.headers.has_key?(name)
        env.response.headers[name] = res.headers[name]
      end
    end
    if res.status_code == 200
      env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
    end

    # env.response << File.read path
    env.response << res.body
  end
end
