require "http/client"

private YT_THUMBNAIL = /^([a-zA-Z0-9-_]{1,8})\.jpg$/

# private DEFAULT_CACHE_CONTROL = "public, max-age=7200"
private DEFAULT_CACHE_CONTROL = "public, max-age=#{2 * 7200}"

private COPY_HEADERS = [
  "Content-Size",
  # "Content-Length", # no need to copy
  "Content-Type",
  # "Cache-Control",
  # "Expires",
]

# "high": {
#   "url": "https://i.ytimg.com/vi/yw8a8n7ZAZg/hqdefault.jpg",
#   "width": 480, "height": 360},
# "maxres": {
#   "url": "https://i.ytimg.com/vi/yw8a8n7ZAZg/maxresdefault.jpg",
#   "width": 1280, "height": 720},
# "medium": {
#   "url": "https://i.ytimg.com/vi/yw8a8n7ZAZg/mqdefault.jpg",
#   "width": 320, "height": 180},
# "default": {
#   "url": "https://i.ytimg.com/vi/yw8a8n7ZAZg/default.jpg",
#   "width": 120, "height": 90},
# "standard": {
#   "url": "https://i.ytimg.com/vi/yw8a8n7ZAZg/sddefault.jpg",
#   "width": 640, "height": 480}}
get "/img/ytv/:video_id/:filename" do |env|
  filename = env.params.url["filename"]

  # pp filename

  unless filename.ends_with? ".jpg"
    env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
    halt_404
  end

  video_id = env.params.url["video_id"]

  # pp video_id

  unless video_id.size == 11
    env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
    halt_404
  end

  meta = Kpbb::Youtube::VideoSnippet::ThumbnailBag.find_by_video_id! video_id

  # pp meta
  # pp meta.thumbnails

  hash = meta.thumbnails
  key = filename[0..-5] # without .jpg
  # pp key

  unless hash.has_key? key
    halt_404
  end

  if url = hash[key].url
    res = HTTP::Client.get(url)
    env.response.status_code = res.status_code
    COPY_HEADERS.each do |name|
      if res.headers.has_key? name
        env.response.headers.add(name, res.headers[name])
      end
    end
    # pp res.headers
    env.response.headers["Cache-Control"] = DEFAULT_CACHE_CONTROL
    env.response << res.body
  else
    halt_404
  end
end
