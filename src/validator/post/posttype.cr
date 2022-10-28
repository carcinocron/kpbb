# require "../../request/post/update"
require "../../request/post/create"

private alias HasPostType = (Kpbb::Request::Post::Create | Kpbb::Request::Post::Update)

class Kpbb::Validator::Post::PType < Accord::Validator
  def initialize(context : HasPostType)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.model.ptype != Kpbb::Post::Type::None
      if @context.parent.nil?
        errors.add(:ptype, "Post with parent requires post type.")
        return
      end
    end
  end
end
