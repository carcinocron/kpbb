macro default_new(name)
  @{{name.var.id}} : {{name.type}}?

  def {{name.var.id}}! : {{name.type}}
    @{{name.var.id}}.not_nil!
  end

  def {{name.var.id}} : {{name.type}}
    @{{name.var.id}} || {{name.type}}.new
  end

  def {{name.var.id}}? : {{name.type}}?
    @{{name.var.id}}
  end
end
