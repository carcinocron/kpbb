require "accord"
require "php-shell-exec"
require "../../validator/**"

module Kpbb::Request::Upload
  struct Creating
    property id : Int64?
    property creator_id : Int64
    property ip : String?
    property ua_id : Int64
    property mime_id : Int64?
    property size : Int64?
    property width : Int16?
    property height : Int16?
    property crc32 : Int64?
    property status : Kpbb::Upload::Status
    property filename : String?
    property typedesc : String?

    def initialize(
      env : HTTP::Server::Context,
      type : Iom::File::FileTypeResult,
      connection : DB::Connection? = nil
    )
      # connection ||= Kpbb.db
      @creator_id = env.session.userId
      # @status = Kpbb::Upload::Status::Pending
      @status = Kpbb::Upload::Status::Uploaded
      @ip = env.request.ip_address!
      @ua_id = Kpbb::Useragent.upsert!(env.request.user_agent!, connection: connection).id
      @mime_id = if type.mime.presence
                   Kpbb::Useragent.upsert!(type.mime, connection: connection).id
                 else
                   nil
                 end
      @typedesc = type.bio
      @crc32 = type.crc32
      @size = type.size.to_i64
      if r = type.resolution
        @width = r.width
        @height = r.height
      end
    end
  end

  struct Create
    property model : Creating | Kpbb::Upload
    property env : HTTP::Server::Context
    property input : HTTP::Params
    property type : Iom::File::FileTypeResult
    property file : Kemal::FileUpload

    # property channeljobs : Array(Kpbb::DraftChannelJob)

    def initialize(@env : HTTP::Server::Context)
      @input = env.params.body
      @file = env.params.files["upload"]
      @type = Iom::File.filetype(@file.tempfile.path)
      @model = Creating.new(@env, @type)
    end

    include Accord
    # include MoreAccord
    validates_with [
      Kpbb::Validator::Upload::File,
    ]

    def save!
      Kpbb.db.transaction do |transaction|
        @model = Kpbb::Upload.save!(
          creator_id: @model.creator_id.not_nil!,
          ip: @model.ip,
          ua_id: @model.ua_id.not_nil!,
          mime_id: @model.mime_id,
          size: @model.size,
          width: @model.width,
          height: @model.height,
          crc32: @model.crc32,
          status: @model.status.not_nil!,
          filename: @model.filename.try(&.strip).presence,
          typedesc: @model.typedesc.try(&.strip).presence,
          connection: transaction.connection)
      end

      uploader = Awscr::S3::FileUploader.new(Kpbb::S3.client)
      s3_uuid = @model.id.not_nil!.to_base62

      s3_filename = "uploads/#{s3_uuid}"
      uploader.upload(Kpbb::S3.bucket, s3_filename, @file.tempfile)

      thumbnail_path = "#{@file.tempfile.path}_#{s3_uuid}_48x48.png"
      Iom::Php::ShellExec.shell_exec("convert", [
        @file.tempfile.path,
        "-resize", "48",
        thumbnail_path,
      ])
      ::File.open thumbnail_path do |file|
        uploader.upload(Kpbb::S3.bucket, s3_filename, file)
      end
      # uploader.upload(Kpbb::S3.bucket, s3_filename, thumbnail_path)
      ::File.delete thumbnail_path

      @model.id
    end
  end
end
