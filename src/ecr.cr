module Kpbb::Ecr::Component
  def self.reply_row(
    ctx : Kpbb::View::Context,
    post : Kpbb::Post,
    postusers : Array(Kpbb::PostUser),
    publicusers : Array(Kpbb::PublicUser),
    channel : Kpbb::Channel? = nil,
    reply_thread : Kpbb::Post::Thread = Kpbb::Post::Thread.new,
    thread_post : Kpbb::Post? = nil,
    parent_post : Kpbb::Post? = nil
  ) : String
    createdby = publicusers.find { |u| u.id == post.creator_id }
    channelmembership = nil
    postuser = postusers.find { |pu| pu.post_id == post.id }
    component "post/reply_row"
  end

  def self.post_row(
    ctx : Kpbb::View::Context,
    post : Kpbb::Post,
    thread : Kpbb::Post::Thread
  ) : String
    auth_user_id = ctx.user.id
    channel = thread.channels.find { |c| c.id == post.channel_id }
    createdby = thread.publicusers.find { |u| u.id == post.creator_id }
    channelmembership = if channel && auth_user_id
                          thread.channelmemberships.find { |cm| cm.channel_id == channel.id && cm.user_id == ctx.user.id }
                        else
                          nil
                        end
    postuser = thread.postusers.find { |pu| pu.post_id == post.id }
    link = thread.link post
    component "post/row2"
  end

  def self.reply_tree(
    ctx : Kpbb::View::Context,
    post : Kpbb::Post,
    thread : Kpbb::Post::Thread
  ) : String
    auth_user_id = ctx.user.id
    channel = thread.channels.find { |c| c.id == post.channel_id }
    createdby = thread.publicusers.find { |u| u.id == post.creator_id }
    channelmembership = if channel && auth_user_id
                          thread.channelmemberships.find { |cm| cm.channel_id == channel.id && cm.user_id == ctx.user.id }
                        else
                          nil
                        end
    postuser = thread.postusers.find { |pu| pu.post_id == post.id }
    link = thread.link post
    component "post/reply_tree"
  end
end
