macro render_view(layout, filename)
  ctx = Kpbb::View::Context.new(env)
  navbar = render "src/views/navbar.ecr"
  render "src/views/pages/#{{{filename}}}.ecr", "src/views/layouts/#{{{layout}}}.ecr"
end

macro component(filename)
  render "src/views/components/#{{{filename}}}.ecr"
end
