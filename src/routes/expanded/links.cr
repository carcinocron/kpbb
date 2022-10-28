get "/expanded/links/:link_id" do |env|
  link : Kpbb::Link = Kpbb::Link.find_by_base62! env
  redirect_if_not_authenticated unless link.active
  halt_403 unless link.active || env.session.admin?

  env.response.headers.merge! Kpbb::Headers::PERM_CACHE_PUBLIC

  if env.request.wants_json
    ({
      :id  => link.id,
      :url => link.url,
      # :thumbnails => link.thumbnails,
    })
  else
    # next
    # ctx = Kpbb::View::Context.new(env)
    env.response << (component "link/thumbnail_expanded").strip
  end
end
