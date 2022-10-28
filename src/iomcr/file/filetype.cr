require "php-shell-exec"

module Iom::File
  def self.filetype(filename)
    begin
      crc32result = Iom::Php::ShellExec.shell_exec("crc32", [
        filename,
      ])
      if crc32result.stderr.includes? "No such file or directory"
        raise crc32result.to_s
      else
        begin
          crc32 = crc32result.stdout.strip.try(&.to_i64(16))
        rescue ex
          # puts crc32result
          raise ex
        end
      end

      # have to use 2 seperate versions of this command to get all the data
      FileTypeResult.new(
        mime: Iom::Php::ShellExec.shell_exec("file", [
          "--mime",
          "-b",
          filename,
        ]).stdout.strip,
        bio: Iom::Php::ShellExec.shell_exec("file", [
          "-b",
          filename,
        ]).stdout.strip,
        # crc32 can be stored as a BIGINT, everything else is complicated
        crc32: crc32,
        size: ::File.size(filename).to_u64
      )
    rescue ex
      p "Iom::File.filetype filename: #{filename}"
      raise ex
    end
  end

  # public/apple-icon.gif: PNG image data, 192 x 192, 8-bit/color RGBA, non-interlaced
  struct FileTypeResult
    include JSON::Serializable

    property mime : String
    property bio : String?
    property size : UInt64
    property crc32 : Int64
    property resolution : FileTypeResult::Resolution? = nil

    def initialize(@mime : String, @bio : String?, @size : UInt64, @crc32 : Int64)
      if (bio = @bio) && (md = bio.match(@@resolution_regex))
        w, h = md[1]?.try(&.to_i16), md[2]?.try(&.to_i16)
        unless w.nil? || h.nil?
          @resolution = FileTypeResult::Resolution.new(width: w, height: h)
        end
      end
    end

    def png? : Bool
      @mime == "image/png; charset=binary"
    end

    def jpg? : Bool
      @mime == "image/jpeg; charset=binary"
    end

    def webp? : Bool
      @mime == "image/webp; charset=binary"
    end

    @@resolution_regex = /,\s{0,1}([1-9][0-9]{0,3})\s{0,1}x\s{0,1}([1-9][0-9]{0,3})/
    # def resolution : FileTypeResult::Resolution?
    #   nil
    # end
  end

  struct FileTypeResult::Resolution
    property width : Int16
    property height : Int16

    def initialize(@width, @height)
    end
  end
end

# list = Array(Iom::File::FileTypeResult).new

# list << Iom::File.filetype("/home/forge/Downloads/1540417809309.webm")
# list << Iom::File.filetype("/home/forge/Downloads/23704122.png")

# list << Iom::File.filetype("/home/forge/Downloads/195825_1788989959003_7288436_n.jpg")
# # JPEG image data, JFIF standard 1.01, resolution (DPI), density 96x96, segment length 16, baseline, precision 8, 720x618, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/2018-02-14-o6wmut3nygqvx1p9o3qyjwvfva47yovz6dvf05pzmo.jpg")
# # JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, comment: "CREATOR: gd-jpeg v1.0 (using IJG JPEG v62), quality = 82", baseline, precision 8, 600x400, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/2dc5d0d9-d915-4701-ac61-03748b19fcb0.jpg")
# # JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, baseline, precision 8, 590x331, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/2qa4d5ay5cu6usvdy.jpg")
# # JPEG image data, progressive, precision 8, 625x790, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/43661895_717871961919021_3940029424837066752_n.jpg")
# # JPEG image data, JFIF standard 1.02, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 480x480, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/43952068_10156915369811165_8158565205119336448_o.jpg")
# # JPEG image data, progressive, precision 8, 1080x1080, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/50846599_2113161218707095_1734917924293967872_n.jpg")
# # JPEG image data, progressive, precision 8, 720x433, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/5317036166_b0cd438853_m.jpg")
# # JPEG image data, Exif standard: [TIFF image data, big-endian, direntries=0], baseline, precision 8, 127x130, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/57c.jpg")
# # JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 640x644, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/96g63znq8e611.jpg")
# # JPEG image data, progressive, precision 8, 556x395, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/ancaps.jpg")
# # JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 563x525, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/Buffalo-Wild-Wings-desk-1-e1575595352653-ohqxvgf4yqzevnqxxa0cyaoyg3nyvibe9c5km2ok2o.jpg")
# # JPEG image data, JFIF standard 1.01, resolution (DPI), density 96x96, segment length 16, comment: "CREATOR: gd-jpeg v1.0 (using IJG JPEG v62), quality = 82", baseline, precision 8, 600x400, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/deep-ocean-background-vector.jpg")
# # JPEG image data, JFIF standard 1.01, resolution (DPI), density 300x300, segment length 16, baseline, precision 8, 1386x980, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/eq90u5wmpw311.jpg")
# # JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, baseline, precision 8, 960x960, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/IMG_20180721_143359.jpg")
# # JPEG image data, Exif standard: [TIFF image data, big-endian, direntries=0], progressive, precision 8, 360x360, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/kcdej8o80dp41.jpg")
# # JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, progressive, precision 8, 742x768, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/ku3qgri4cm611.jpg")
# # JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, baseline, precision 8, 750x1334, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/sA6IjR9.jpg")
# # JPEG image data, Exif standard: [TIFF image data, big-endian, direntries=0], comment: "Optimized by JPEGmini 3.14.14.72670860 0x939f87f1", baseline, precision 8, 1066x582, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/shutterstock_547308685.jpg")
# # JPEG image data, JFIF standard 1.01, resolution (DPI), density 300x300, segment length 16, baseline, precision 8, 1075x555, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/SUNY-Rockland-e1532372494420-o6wmhjlniml834yv4dchd9da3jhrcg8c0qgr7ldzfk.jpg")
# # JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, comment: "CREATOR: gd-jpeg v1.0 (using IJG JPEG v62), quality = 82", baseline, precision 8, 600x400, frames 3
# list << Iom::File.filetype("/home/forge/Downloads/unnamed.jpg")
# # JPEG image data, JFIF standard 1.01, aspect ratio, density 1x1, segment length 16, Exif Standard: [TIFF image data, little-endian, direntries=1, software=Picasa], baseline, precision 8, 600x300, frames 3

# pp list

# module Iom::Util
#   def self.shell_exec(cmd, args : Array(String)? = nil, shell = false)
#     stdout = IO::Memory.new
#     stderr = IO::Memory.new
#     p = Process.new(cmd, args: args, output: stdout, error: stderr, shell: shell)
#     status = p.wait
#     ShellExecResult.new cmd, args, status.exit_code, stdout.to_s, stderr.to_s
#   end

#   struct ShellExecResult
#     property exit_code : Int32
#     property cmd : String
#     property stdout : String
#     property stderr : String
#     property args : Array(String) | Nil

#     def initialize(@cmd, @args, @exit_code, @stdout, @stderr)
#     end
#   end
# end
