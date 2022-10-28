require "../request/post/create"
require "../request/post/update"

get "/posts" do |env|
  page = Kpbb::Post.fetch_page(env)
  channels = Kpbb::Channel.find page
  links = Kpbb::Link.find page
  postusers = Kpbb::PostUser.find page, env.session.userId?
  channelmemberships = Kpbb::ChannelMembership.find page, env.session.userId?
  publicusers = Kpbb::PublicUser.find page.collection.compact_map(&.creator_id)

  if env.request.wants_json
    next (page.to_json do |collection|
      collection.map do |p|
        channel = channels.find { |c| c.id == p.channel_id }
        pu = postusers.find { |pu| pu.post_id == p.id }
        {
          :id         => p.id,
          :creator_id => p.creator_id,
          # :channel_id => p.channel_id,
          :title        => p.title,
          :tags         => p.tags,
          :url          => p.url,
          :link_id      => p.link_id,
          :body_md      => p.body_md,
          :body_html    => p.body_html,
          :score        => p.score,
          :dreplies     => p.dreplies,
          :treplies     => p.treplies,
          :posted       => p.posted,
          :draft        => p.draft,
          :published_at => p.published_at.try(&.to_unix),
          :created_at   => p.created_at.to_unix,
          :updated_at   => p.updated_at.to_unix,
          :channel      => channel ? {
            :id     => channel.id,
            :handle => channel.handle,
            :dname  => channel.dname,
            :bio    => channel.bio,
            :avatar => channel.avatar,
            :banner => channel.banner,
            :public => channel.public,
            :listed => channel.listed,
          } : nil,
          :postuser => pu ? {
            :saved  => !pu.saved_at.nil?,
            :hidden => pu.hidden,
          } : nil,
        }
      end
    end)
  end
  render_view "default", "posts/index"
end

get "/posts/create" do |env|
  redirect_if_not_authenticated
  channels = Kpbb::Channel.find_for_post_create env
  render_view "default", "posts/create"
end

get "/posts/:post_id/reply" do |env|
  redirect_if_not_authenticated
  halt_501 if env.request.wants_json

  channels = Kpbb::Channel.find_for_post_reply env
  halt_404 unless (post_id = env.params.url["post_id"]?.try(&.to_i64_from_slug_prefixed_b62?))
  thread = Kpbb::Post::Thread.fetch(post_id, children: false)
  halt_404 unless post = thread.context?
  parent_post : Kpbb::Post = thread.context
  thread_post : Kpbb::Post = thread.context
  channel : Kpbb::Channel = Kpbb::Channel.find! post.channel_id
  parent_channel : Kpbb::Channel = channel
  link : Kpbb::Link? = Kpbb::Link.find? post.link_id
  domain : Kpbb::Domain? = Kpbb::Domain.find_by_link? link
  reply_thread = Kpbb::Post.fetch_reply_thread env
  parent_createdby = Kpbb::PublicUser.find? post.creator_id
  postusers = Kpbb::PostUser.find(reply_thread.list.map(&.id).concat([post.id]), env.session.userId?)
  user_id_list = reply_thread.list.compact_map(&.creator_id)
  user_id_list << post.creator_id.not_nil! if post.creator_id
  user_id_list.uniq!
  publicusers = Kpbb::PublicUser.find(user_id_list)

  halt_404 unless channel.public || !post.draft || env.session.can.edit? post
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil

  render_view "default", "posts/_post_id/quick_reply"
end

get "/posts/:post_id" do |env|
  halt_404 unless (post_id = env.params.url["post_id"]?.try(&.to_i64_from_slug_prefixed_b62?))
  channel : Kpbb::Channel?
  if env.request.wants_json
    post = Kpbb::Post.find! env
    channel = Kpbb::Channel.find?(post.channel_id)
    if post.draft || !(channel && channel.public)
      halt_404 unless env.session.can.edit?(post)
    end
    next {:id => post.id}.to_json
  end
  thread = Kpbb::Post::Thread.fetch(post_id, children: true)
  halt_404 unless post = thread.context?
  parent_post : Kpbb::Post = thread.context
  thread_post : Kpbb::Post = thread.context
  # p thread.list.size
  # # p thread.list.map(&.id)
  # p thread.list.map { |p| ({:id => p.id, :parent_id => p.parent_id}) }
  # # p thread.has_children?
  # p thread.children?.try(&.map { |p| ({:id => p.id, :parent_id => p.parent_id}) })
  # # p thread.has_parents
  # p thread.parents.try(&.map { |p| ({:id => p.id, :parent_id => p.parent_id}) })

  halt_404 unless (channel = thread.channels.find { |c| c.id == post.channel_id })
  link : Kpbb::Link? = Kpbb::Link.find? post.link_id
  domain : Kpbb::Domain? = Kpbb::Domain.find_by_link? link
  createdby = Kpbb::PublicUser.find? post.creator_id
  postuser = env.session.userId? ? Kpbb::PostUser.find?(post.id, env.session.userId) : nil
  reply_thread = Kpbb::Post.fetch_thread env
  postusers = Kpbb::PostUser.find(reply_thread.list.map(&.id).concat([post.id]), env.session.userId?)
  user_id_list = reply_thread.list.compact_map(&.creator_id)
  user_id_list << post.creator_id.not_nil! if post.creator_id
  user_id_list.uniq!
  publicusers = Kpbb::PublicUser.find(user_id_list)

  if post.draft || !(channel && channel.public)
    halt_404 unless env.session.can.edit?(post)
  end
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil

  render_view "default", "posts/_post_id/index"
end

get "/posts/:post_id/edit" do |env|
  redirect_if_not_authenticated

  channels = Kpbb::Channel.find_for_post_reply env
  halt_404 unless (post_id = env.params.url["post_id"]?.try(&.to_i64_from_slug_prefixed_b62?))
  thread = Kpbb::Post::Thread.fetch(post_id, children: false)
  halt_404 unless post = thread.context?
  parent_post : Kpbb::Post = thread.context
  thread_post : Kpbb::Post = thread.context
  channel : Kpbb::Channel = Kpbb::Channel.find! post.channel_id
  link : Kpbb::Link? = Kpbb::Link.find? post.link_id
  domain : Kpbb::Domain? = Kpbb::Domain.find_by_link? link
  halt_404 unless channel.public || !post.draft || env.session.can.edit? post
  halt_403 unless env.session.can.edit? post
  channelmembership = env.session.userId? ? Kpbb::ChannelMembership.find?(channel.id, env.session.userId) : nil
  render_view "default", "posts/_post_id/edit"
end

post "/posts/:post_id" do |env|
  redirect_if_not_authenticated
  post : Kpbb::Post = Kpbb::Post.find! env
  channel : Kpbb::Channel = Kpbb::Channel.find! post.channel_id
  halt_404 unless channel.public || !post.draft || env.session.can.edit? post
  halt_403 unless env.session.can.edit? post
  data = Kpbb::Request::Post::Update.new(post, env)
  data.validate!
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data{
        "title"   => data.model.title || "",
        "tags"    => data.model.tags || "",
        "body_md" => data.model.body_md || "",
        "url"     => data.model.url || "",
        "draft"   => one_or_zero(data.model.draft).to_s,
      }))
      redirect_back data.model.relative_url + "/edit"
    end
  end

  data.save

  if env.request.wants_json
    next JSON_MESSAGE_OK
  end
  redirect_intended data.model.relative_title_url
end

post "/posts" do |env|
  redirect_if_not_authenticated
  data = Kpbb::Request::Post::Create.new(
    body: env.params.body,
    creator_id: env.session.userId,
    cc_i16: env.request.cc_i16,
    ip: env.request.ip_address!)

  data.validate!
  # pp data.model
  # pp data.errorshashstring
  if data.errors.any?
    if env.request.wants_json
      halt env, status_code: 422, response: data.to_json
    else
      env.session.object("fe", FlashErrors.new(data.errorshashstring))
      env.session.object("fo", FlashOld.new(FlashOld::Data{
        "channel_id" => data.model.channel_id.try(&.to_b62) || "",
        "title"      => data.model.title || "",
        "tags"       => data.model.tags || "",
        "body_md"    => data.model.body_md || "",
        "url"        => data.model.url || "",
        "draft"      => one_or_zero(data.model.draft).to_s,
        "posted"     => one_or_zero(data.model.posted).to_s,
      }))
      redirect_back "/posts/create"
    end
    next
  end

  data.save!

  if env.request.wants_json
    next {:id => data.model.id}.to_json
  end
  redirect_intended data.model.relative_title_url
end
