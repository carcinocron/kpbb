require "../../request/post/update"
require "../../request/post/create"

private alias HasPostTitle = (Kpbb::Request::Post::Create | Kpbb::Request::Post::Update)

class Kpbb::Validator::Post::Title < Accord::Validator
  def initialize(context : HasPostTitle)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.model.ptype == Kpbb::Post::Type::Comment && @context.model.title.nil?
      return # for comment, we'll show the error on body_md
    end
    if (title = @context.model.title).nil?
      errors.add(:title, "Title required.")
      return
    end
    size = @context.model.title.not_nil!.size
    errors.add(:title, "Title must be between 3 and 255 characters.") if size < 3 || size > 255
  end
end
