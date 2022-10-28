struct Gate
  property userId : Int64?
  user : Kpbb::PolicyUser?

  def initialize(@user : Kpbb::PolicyUser)
    @userId = @user.id
  end

  def initialize(@userId : Int64?)
    @user = nil
  end

  def user : Kpbb::PolicyUser?
    if @user.nil? && @userId
      @user = Kpbb::PolicyUser.find? @userId.not_nil!
    end
    @user
  end

  def edit?(model : Kpbb::Post | Kpbb::Channel) : Bool
    if model.creator_id == @userId
      return true
    end
    admin?
  end

  def admin? : Bool
    u = user
    if u && u.rank > 0
      return true
    end
    return false
  end
end
