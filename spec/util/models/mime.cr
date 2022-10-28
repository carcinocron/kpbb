private RANDOM_LIST = [
  "application/javascript",
  "text/javascript",
  "image/apng",
  "image/png",
  "image/gif",
  "image/jpeg",
  "image/x-icon",
  "image/svg+xml",
  "image/tiff",
  "image/webp",

  "audio/wave",
  "audio/wav",
  "audio/x-wav",
  "audio/x-pn-wav",
  "audio/webm",
  "video/webm",
  "audio/ogg",
  "video/ogg",
  "application/ogg",
]

struct Kpbb::Mime
  def self.factory(value : String? = nil) : self
    value ||= RANDOM_LIST[Random.rand(RANDOM_LIST.size - 1)]
    self.upsert!(value: value.not_nil!)
  end
end
