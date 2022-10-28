module Kpbb::Headers
  PERM_CACHE_PUBLIC = HTTP::Headers{
    "Cache-Control" => "public, max-age=604800, immutable",
  }

  PNG = HTTP::Headers{
    "Content-Type" => "image/png",
  }

  SVG = HTTP::Headers{
    "Content-Type" => "image/svg+xml",
  }
end
