module Kpbb::Themes
  @@themes = Array(Kpbb::Themes::Theme).new
  @@themes_map_by_id = Hash(Int16, Kpbb::Themes::Theme).new

  # @@themes_map_by_name = Hash(String, Kpbb::Themes::Theme).new

  def self.list
    @@themes
  end

  def self.map_by_id
    @@themes_map_by_id
  end

  # def self.map_by_name ()
  #   @@themes_map_by_name
  # end

  struct Theme
    property id : Int16
    property name : String
    property path : String
    property icon_color : String?
    @dark : Bool = false

    def initialize(@id : Int16, @name : String, @path : String, @icon_color : String? = nil)
      # file_content = File.read("public#{@path}")
      # if md = file_content.match /body.{2,256};color:(#[abcdefABCDEF0-9]{3,6});/
      #   # puts md
      #   # puts md[0]
      #   puts md[1]
      # end
    end

    def dark : self
      @dark = true
      self
    end

    def dark? : Bool
      @dark
    end

    @[AlwaysInline]
    def cssfile : String
      @path
    end
  end
end

themes = Kpbb::Themes.list
themes << Kpbb::Themes::Theme.new(id: 0_i16, name: "default", path: "/static/t/slate/app.css", icon_color: "#aaa").dark
themes << Kpbb::Themes::Theme.new(id: 1_i16, name: "cerulean", path: "/static/t/cerulean/app.css", icon_color: "#495057")
themes << Kpbb::Themes::Theme.new(id: 2_i16, name: "cosmo", path: "/static/t/cosmo/app.css", icon_color: "#373a3c")
themes << Kpbb::Themes::Theme.new(id: 3_i16, name: "cyborg", path: "/static/t/cyborg/app.css", icon_color: "#ADAFAE")
themes << Kpbb::Themes::Theme.new(id: 4_i16, name: "darkly", path: "/static/t/darkly/app.css", icon_color: "#fff").dark
themes << Kpbb::Themes::Theme.new(id: 5_i16, name: "flatly", path: "/static/t/flatly/app.css", icon_color: "#212529")
themes << Kpbb::Themes::Theme.new(id: 6_i16, name: "journal", path: "/static/t/journal/app.css", icon_color: "#222")
themes << Kpbb::Themes::Theme.new(id: 7_i16, name: "litera", path: "/static/t/litera/app.css", icon_color: "#343a40")
themes << Kpbb::Themes::Theme.new(id: 8_i16, name: "lumen", path: "/static/t/lumen/app.css", icon_color: "#222")
themes << Kpbb::Themes::Theme.new(id: 9_i16, name: "lux", path: "/static/t/lux/app.css", icon_color: "#55595c")
themes << Kpbb::Themes::Theme.new(id: 10_i16, name: "materia", path: "/static/t/materia/app.css", icon_color: "#444")
themes << Kpbb::Themes::Theme.new(id: 11_i16, name: "minty", path: "/static/t/minty/app.css", icon_color: "#888")
themes << Kpbb::Themes::Theme.new(id: 12_i16, name: "pulse", path: "/static/t/pulse/app.css", icon_color: "#444")
themes << Kpbb::Themes::Theme.new(id: 13_i16, name: "sandstone", path: "/static/t/sandstone/app.css", icon_color: "#3E3F3A")
themes << Kpbb::Themes::Theme.new(id: 14_i16, name: "simplex", path: "/static/t/simplex/app.css", icon_color: "#212529")
themes << Kpbb::Themes::Theme.new(id: 15_i16, name: "sketchy", path: "/static/t/sketchy/app.css", icon_color: "#212529")
themes << Kpbb::Themes::Theme.new(id: 16_i16, name: "slate", path: "/static/t/slate/app.css", icon_color: "#aaa").dark
themes << Kpbb::Themes::Theme.new(id: 17_i16, name: "solar", path: "/static/t/solar/app.css", icon_color: "#839496").dark
themes << Kpbb::Themes::Theme.new(id: 18_i16, name: "spacelab", path: "/static/t/spacelab/app.css", icon_color: "#777")
themes << Kpbb::Themes::Theme.new(id: 19_i16, name: "superhero", path: "/static/t/superhero/app.css", icon_color: "#EBEBEB").dark
themes << Kpbb::Themes::Theme.new(id: 20_i16, name: "united", path: "/static/t/united/app.css", icon_color: "#333")
themes << Kpbb::Themes::Theme.new(id: 21_i16, name: "yeti", path: "/static/t/yeti/app.css", icon_color: "#222")

themes_map_by_id = Kpbb::Themes.map_by_id
# themes_map_by_name = Kpbb::Themes.map_by_name()
themes.each do |t|
  themes_map_by_id[t.id] = t
  # themes_map_by_name[t.name] = t
end
