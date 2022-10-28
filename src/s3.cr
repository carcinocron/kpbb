require "awscr-s3"

module Kpbb::S3
  @@client : Awscr::S3::Client?
  @@bucket : String?

  def self.bucket : String
    @@bucket ||= ENV["S3_BUCKET"]
  end

  def self.client : Awscr::S3::Client
    @@client ||= Awscr::S3::Client.new(
      ENV["S3_REGION"]? || "us-west1",
      ENV["S3_KEY"]? || "key",
      ENV["S3_SECRET"]? || "secret",
      # signer: :v2
      endpoint: ENV["S3_ENDPOINT"]?
    )
  end
end
