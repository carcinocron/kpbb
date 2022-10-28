require "../../request/upload/create"
require "../../request/upload/update"

alias HasUploadFile = (Kpbb::Request::Upload::Create | Kpbb::Request::Upload::Update)

class Kpbb::Validator::Upload::File < Accord::Validator
  def initialize(context : HasUploadFile)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.env.params.files["upload"]?.nil?
      if @context.model.id.nil?
        errors.add(:upload, "File required.")
      else
        # file not required unless replacing
      end
      return
    end
    file : Kemal::FileUpload = @context.env.params.files["upload"]

    if (file.filename.try(&.size) || 0) > 255
      errors.add(:upload, "Invalid file name.")
      return
    end
    if (type = @context.type).nil?
      errors.add(:upload, INVALID_OR_CORRUPT)
      return
    end
    if !(type.png? || type.jpg? || type.webp?)
      errors.add(:upload, INVALID_OR_CORRUPT)
      return
    end
    if (size = file.tempfile.size).nil?
      errors.add(:upload, "Invalid file size.")
      return
    elsif size > 2 * 1024 * 1024 # 2MB
      errors.add(:upload, "File is too big.")
      return
    end
    if r = type.resolution
      if !(r.width >= 32)
        errors.add(:upload, IMAGE_TOO_SMALL)
        return
      end
      if r.width > 10000
        errors.add(:upload, INVALID_OR_CORRUPT)
        return
      end
      if !(r.height >= 32)
        errors.add(:upload, IMAGE_TOO_SMALL)
        return
      end
      if r.height > 10000
        errors.add(:upload, INVALID_OR_CORRUPT)
        return
      end
    else
      errors.add(:upload, INVALID_OR_CORRUPT)
      return
    end
  end
end

private IMAGE_TOO_SMALL    = "Image too small."
private INVALID_OR_CORRUPT = "Invalid or corrupt file type."
