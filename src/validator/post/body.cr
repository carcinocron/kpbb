require "../../request/channel/update"
require "../../request/channel/create"

private alias HasPostBody = (Kpbb::Request::Post::Create | Kpbb::Request::Post::Update)

class Kpbb::Validator::Post::Body < Accord::Validator
  def initialize(context : HasPostBody)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if (body_md = @context.model.body_md).nil? && @context.model.title.nil? && @context.model.url.nil?
      if @context.model.ptype == Kpbb::Post::Type::Comment
        errors.add(:body_md, "Cannot be empty.")
      end
    end
    # not required!
    return if body_md.nil?
    size = body_md.size
    errors.add(:body_md, "body must be under 32,000 characters.") if size > 32000
  end
end
