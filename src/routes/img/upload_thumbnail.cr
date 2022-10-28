require "http/client"

private THUMBNAIL = /^([a-zA-Z0-9]{1,8})\.png$/

# original
get "/img/uo/:filename" do |env|
  filename = env.params.url["filename"]

  halt_404 unless filename.ends_with? ".png"
  halt_404 unless md = THUMBNAIL.match filename

  res = Kpbb::S3.client.get_object(Kpbb::S3.bucket, "uploads/#{md[1]}")
  env.response << res.body

  env.response.headers.merge! Kpbb::Headers::PNG
  env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
end

Kpbb::Thumbnail.list.each do |thumbnail|
  get "/img/u#{thumbnail.c}/:filename" do |env|
    filename = env.params.url["filename"]

    unless filename.ends_with? ".png"
      env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
      halt_404
    end
    # halt_404 unless THUMBNAIL.matches? filename # only in 0.35
    unless md = THUMBNAIL.match filename
      env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
      halt_404
    end

    id = md[1]

    begin
      res = Kpbb::S3.client.get_object(Kpbb::S3.bucket, "uploads/#{id}")
    rescue ex : Awscr::S3::NoSuchKey
      halt_404
    end

    tempfile = File.tempfile "_#{id}" do |file|
      file << res.body
    end

    path = thumbnail.convert tempfile

    # need to set headers first, otherwise they're already sent
    env.response.headers.merge! Kpbb::Headers::PNG
    env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC

    env.response << File.read path
  end
end
