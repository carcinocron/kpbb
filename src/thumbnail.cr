require "php-shell-exec"

# sudo apt install webp
# https://www.tecmint.com/convert-images-to-webp-format-in-linux/

module Kpbb::Thumbnail
  @@thumbnails = Array(Kpbb::Thumbnail::Thumbnail).new

  def self.list
    @@thumbnails
  end

  def self.smallest
    @@thumbnails.first
  end

  def self.largest
    @@thumbnails.last
  end

  class Thumbnail
    property c : String
    property width : Int32
    property height : Int32
    @trim = false

    def initialize(@c, @width, @height)
    end

    def trim
      @trim = true
      self
    end

    def convert(tempfile) : String
      result_path = tempfile.path

      filetype = Iom::File.filetype result_path
      # pp ({"#result_path}" => Iom::File.filetype result_path})

      if filetype.webp?
        res = Iom::Php::ShellExec.shell_exec "dwebp", [
          result_path, "-o", (result_path = result_path + "_nowpng"),
        ]
        if res.exit_code != 0 || res.stdout.presence # || res.stderr.presence
          # puts res
          raise res.to_s
        end
      end

      args = [result_path]

      args << "-regard-warnings"
      args << "-trim"
      # args << "-trim" if @trim

      args << "-resize"
      args << "#{@width}x#{@height}^>"

      args << "-gravity"

      args << "center"

      # args << "-extent"
      # args << "#{@width}x#{@height}"

      # output file
      args << (result_path = tempfile.path + "_b")

      res = Iom::Php::ShellExec.shell_exec "convert", args
      if res.exit_code != 0 || res.stdout.presence # || res.stderr.presence
        # puts res
        raise res.to_s
      end
      # pp ({"#result_path}" => Iom::File.filetype result_path})

      res = Iom::Php::ShellExec.shell_exec "cwebp", [
        result_path,
        "-q", "75", # 0..100 default=75
        "-o", (result_path = result_path + "_to_webp"),
      ]
      if res.exit_code != 0 || res.stdout.presence # || res.stderr.presence
        # puts res
        raise res.to_s
      end
      # pp ({"#result_path}" => Iom::File.filetype result_path})

      # "Resize to fit"
      # convert input.jpg -resize 80x80^ -gravity center -extent 80x80 icon

      result_path
    end
  end
end

list = Kpbb::Thumbnail.list
list << Kpbb::Thumbnail::Thumbnail.new("a", 120, 90).trim
list << Kpbb::Thumbnail::Thumbnail.new("b", 320, 180).trim
list << Kpbb::Thumbnail::Thumbnail.new("c", 480, 360).trim
list << Kpbb::Thumbnail::Thumbnail.new("d", 640, 480).trim
list << Kpbb::Thumbnail::Thumbnail.new("e", 1280, 720).trim
list << Kpbb::Thumbnail::Thumbnail.new("f", 1920, 1080).trim
list << Kpbb::Thumbnail::Thumbnail.new("g", 3000, 3000).trim

# YouTube
# default –  video=120x90, channel=88x88
# medium –   video=320x180, channel=240x240
# high –     video=480x360, channel=800x800
# standard – 640x480
# maxres –   1280x720
