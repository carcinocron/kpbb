require "../../request/post/update"
require "../../request/post/create"

private alias HasPostUrl = (Kpbb::Request::Post::Create | Kpbb::Request::Post::Update)

class Kpbb::Validator::Post::Url < Accord::Validator
  def initialize(context : HasPostUrl)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.model.url.nil? || @context.model.url == ""
      # not required
      return
    end
    url = @context.model.url.not_nil!.strip

    unless url.starts_with? "https://"
      errors.add(:url, "URL must start with https://")
      return
    end

    if @context.model.id
      # short circuit duplicate check if post already exists
    elsif (dedupe_minutes = @context.body["dedupe_minutes"]?.try(&.to_i64)) && dedupe_minutes > 0
      query = <<-SQL
        SELECT id FROM posts
        WHERE posts.channel_id = $1
        AND posts.posted IS TRUE
        AND posts.draft IS FALSE
        AND posts.published_at >= $2
        AND posts.url = $3
        ORDER BY posts.id DESC
        LIMIT 1
      SQL

      # @link https://github.com/jacktuck/unfurl/issues/29
      # @todo check canonical links

      bindings = [
        @context.model.channel_id,
        Time.utc - dedupe_minutes.minutes,
        url,
      ]

      bc = ::Raven::Breadcrumb.record(
        data: {:bindings => bindings, :query => query},
        category: "sql.query")
      duplicate_of_id = nil
      start_at = Time.monotonic
      begin
        begin
          duplicate_of_id = Kpbb.db.query_one query, args: bindings, as: {Int64}
        rescue ex : DB::NoResultsError
          # pass
        end
      ensure
        bc.data[:duration] = (Time.monotonic - start_at).milliseconds
      end
      if duplicate_of_id
        errors.add(:url, "URL was already submitted recently.")
        errors.add(:duplicate_of_id, duplicate_of_id.to_s)
      end
    end
  end
end
