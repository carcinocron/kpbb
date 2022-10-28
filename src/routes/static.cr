require "http/client"

private COPY_HEADERS = [
  "Content-Size",
  # "Content-Length",
  "Content-Type",
]

get "/static/fi/:theme_id/:filename" do |env|
  themes_map_by_id = Kpbb::Themes.map_by_id

  theme_id = env.params.url["theme_id"]?.try(&.to_i64_from_b62?).try(&.to_i16)
  # puts ({theme_id: theme_id})
  halt_404 unless theme_id
  theme = themes_map_by_id[theme_id]?
  # puts ({theme: theme})
  halt_404 unless theme

  filename = env.params.url["filename"].gsub(/[^a-z\-_\.]/, "-")

  halt_404 unless filename.ends_with? ".svg"

  # puts ({filename: filename})
  file_content = File.read("public/static/fi/#{filename}")

  if theme.icon_color
    file_content = file_content.gsub(/\bcurrentColor\b/, theme.icon_color)
  end

  env.response.headers.merge! Kpbb::Headers::SVG
  env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
  # env.response.headers.add(name, res.headers[name])
  # response.headers.add("Content-Size", filestat.size.to_s)

  env.response << file_content
end

# run the bootswatch server with
# npx grunt connect:base swatch:slate watch
# or
# npx grunt connect:base swatch watch
# get "/static/t/:theme_id/b.css" do |env|
#   # halt_404 unless backend_path = ENV["BOOTSWATCH_PATH"]?
#   themes_map_by_id = Kpbb::Themes.map_by_id

#   theme_id = env.params.url["theme_id"]?.try(&.to_i64_from_b62?).try(&.to_i16)
#   # puts ({theme_id: theme_id})
#   halt_404 unless theme_id
#   theme = themes_map_by_id[theme_id]?
#   # puts ({theme: theme})
#   halt_404 unless theme

#   filename = "b.css"

#   url = if theme.name == "default"
#           "#{backend_path}slate/bootstrap.min.css"
#         else
#           "#{backend_path}#{theme.name}/bootstrap.min.css"
#         end
#   # pp url
#   res = HTTP::Client.get(
#     url: url,
#     headers: HTTP::Headers{"Accept" => "text/css,*/*;q=0.1"})
#   # pp res
#   # pp res.headers # @todo unnest result

#   COPY_HEADERS.each do |name|
#     if res.headers.has_key?(name)
#       env.response.headers[name] = res.headers[name]
#     end
#   end

#   # if IS_PRODUCTION
#   #   env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC
#   # end
#   # pp env.response.headers

#   env.response << res.body
# end
