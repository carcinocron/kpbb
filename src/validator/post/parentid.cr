require "../../request/post/update"
require "../../request/post/create"

private alias HasParentId = (Kpbb::Request::Post::Create | Kpbb::Request::Post::Update)

class Kpbb::Validator::Post::ParentId < Accord::Validator
  def initialize(context : HasParentId)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if (parent_id = @context.model.parent_id).nil?
      # errors.add(:parent_id, "Post required.")
      return
    end

    if (parent = @context.parent).nil?
      errors.add(:parent_id, "Post does not exist.")
      return
    end

    unless (parent = @context.parent).nil?
      channelmembership = @context.channelmembership
      if parent.dead
        if channelmembership && channelmembership.rank > 0
          errors.add(:parent_id, "Post is dead.")
          return
        end
      end
      if parent.locked
        if channelmembership && channelmembership.rank > 0
          errors.add(:parent_id, "Post is locked.")
          return
        end
      end
    end

    # @todo reject users from making too many comments
    # @todo reject users with bad reputation from making comments
  end
end
