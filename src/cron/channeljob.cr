module Kpbb::Cron::ChannelJob
  def self.run(minute : Time) : Nil
    Kpbb.db.transaction do |transaction|
      list = Kpbb::ChannelJob.all_for_minute(
        minute: minute, connection: transaction.connection)
      list.each do |channeljob|
        case channeljob.action
        when Kpbb::ChannelAction::Publish
          table : String = if !channeljob.comment_id.nil?
            "comments"
          elsif !channeljob.post_id.nil?
            "posts"
          else
            # not implemented
            break
          end
          query = <<-SQL
            UPDATE #{table} SET draft = false, published_at = NOW()
            WHERE #{table}.id = $1 AND #{table}.draft IS TRUE
          SQL
          bindings = [channeljob.post_id]
          result : DB::ExecResult = transaction.connection.exec(query, args: bindings)

          Kpbb::ChannelLog.save!(
            user_id: channeljob.user_id,
            channel_id: channeljob.channel_id,
            post_id: channeljob.post_id,
            comment_id: channeljob.comment_id,
            action: channeljob.action,
            data: Kpbb::ChannelLogData.new(
              rows_affected: result.rows_affected,
              job: channeljob).to_json,
            connection: transaction.connection)

          # delete channeljob
          transaction.connection.exec("DELETE FROM channeljobs WHERE id = $1", args: [channeljob.id])
          transaction.commit
        else
          # skip, unknown action
        end
      end
    end
  end
end
