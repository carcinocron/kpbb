require "http/client"

private DICEBEAR_JDENTICON_URL = ENV["KPBB_IMG_API"] + "/dicebear/jdenticon"
private DICEBEAR_IDENTICON_URL = ENV["KPBB_IMG_API"] + "/dicebear/identicon"

private COPY_HEADERS = [
  "Content-Size",
  # "Content-Length", # no need to copy
  "Content-Type",
]

get "/img/0/:seed" do |env|
  url = DICEBEAR_JDENTICON_URL + "/" + env.params.url["seed"]
  res = HTTP::Client.get(url)
  env.response.status_code = res.status_code
  COPY_HEADERS.each do |name|
    if res.headers.has_key? name
      env.response.headers.add(name, res.headers[name])
    end
  end
  env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
  env.response << res.body
end

get "/img/1/:seed" do |env|
  url = DICEBEAR_IDENTICON_URL + "/" + env.params.url["seed"]
  res = HTTP::Client.get(url)
  env.response.status_code = res.status_code
  COPY_HEADERS.each do |name|
    if res.headers.has_key? name
      env.response.headers.add(name, res.headers[name])
    end
  end
  env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
  # probably duplication
  env.response << res.body
  # probably piping
  # empty responses :(
  # if b_io = res.body_io?
  #   IO.copy b_io, env.response
  # end
end
