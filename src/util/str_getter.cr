macro str_getter(name)
  @{{name}}: String?

  def {{name.id}}! : String
    @{{name.id}}.not_nil!
  end

  def {{name.id}} : String
    @{{name.id}} || ""
  end

  def {{name.id}}? : String?
    @{{name.id}}
  end
end
