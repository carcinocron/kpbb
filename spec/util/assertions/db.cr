# userId Int64 = assert exists
# userId Nil = assert DNE
def assert_handle_session_user_id(handle : String, userId : Int64?)
  begin
    userIdInSession : Int64? = Kpbb.db.query_one(<<-SQL,
      SELECT ((sessions.data::json) -> 'bigints' ->> 'userId')::bigint as user_id
      from sessions
      WHERE ((sessions.data::json) -> 'strings' ->> 'handle')::text = $1
      LIMIT 1
    SQL
      args: [
        handle,
      ], as: Int64?)
    userIdInSession.should eq userId
  rescue ex : DB::NoResultsError
    userId.should eq nil
  end
end

def assert_login_attempts(success : Int64, failed : Int64)
  actual_success_count, actual_failed_count, actual_null_count = Kpbb.db.query_one <<-SQL,
    SELECT
      (SELECT COUNT(*) FROM loginattempts WHERE success IS TRUE) AS success_true,
      (SELECT COUNT(*) FROM loginattempts WHERE success IS FALSE) AS success_false,
      (SELECT COUNT(*) FROM loginattempts WHERE success IS NULL) AS success_null
  SQL
    as: {Int64, Int64, Int64}
  # success should never be null
  actual_null_count.should eq 0
  # assert success and failed together
  "success: #{actual_success_count} failed: #{actual_failed_count}"
    .should eq "success: #{success} failed: #{failed}"
end
