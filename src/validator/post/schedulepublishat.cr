require "php-strtotime"
require "../../request/post/update"
require "../../request/post/create"

private alias HasPostSchedulePublishAt = (Kpbb::Request::Post::Create | Kpbb::Request::Post::Update)

class Kpbb::Validator::Post::SchedulePublishAt < Accord::Validator
  def initialize(@context : HasPostSchedulePublishAt)
  end

  def call(errors : Accord::ErrorList)
    schedule_publish_at_input = (@context.body["schedule_publish_at"]? || "").to_s.strip

    return unless schedule_publish_at_input.size > 0
    return if schedule_publish_at_input == "now"

    # will the resulting state be a draft?
    is_draft : Bool = if @context.body.has_key?("draft")
      @context.body.truthy?("draft")
    else
      @context.model.draft
    end
    unless is_draft
      errors.add(:schedule_publish_at, "Post must be draft in order to schedule for publish.")
      return
    end

    schedule_publish_at : Time? = Time.utc
    unless schedule_publish_at_input == "next"
      schedule_publish_at = Iom::PHP::Strtotime.strtotime(schedule_publish_at_input)
    end
    # puts ({schedule_p: schedule_publish_at})
    if schedule_publish_at.nil?
      errors.add(:schedule_publish_at, "Schedule publish post at timestamp could not be interpreted.")
      return
    end

    @context.channeljobs << Kpbb::DraftChannelJob.new(
      action: Kpbb::ChannelAction::Publish,
      run_at: schedule_publish_at,
      queued: true)

    # @todo reject users from using schedule_publish_at too many times
    # @todo reject users from using schedule_publish_at without channel badge
    # @todo reject users from using schedule_publish_at without user rank
  end
end
