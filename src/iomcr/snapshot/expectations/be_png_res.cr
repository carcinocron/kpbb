require "file"
require "php-shell-exec"

private HEADER_CONTENT_TYPE_PNG               = "image/png"
private HEADER_X_FRAME_OPTIONS_DENY           = "DENY"
private HEADER_X_CONTENT_TYPE_OPTIONS_NOSNIFF = "nosniff"
private HEADER_X_XSS_PROTECTION_MODE_BLOCK    = "1; mode=block"

module Iom::Spec
  struct BePngResponseExpectation
    def initialize
      @needle = "�PNG"
    end

    def match(actual_res)
      unless actual_res.body[1, @needle.size].starts_with? @needle[1, @needle.size]
        @message = <<-RAW
        Expected: starts with "#{@needle}"
        Actual: starts with "#{actual_res.body[0, @needle.size]}"
        RAW
        return false
      end
      unless (content_type = actual_res.headers["Content-Type"]?) && content_type == HEADER_CONTENT_TYPE_PNG
        @message = <<-RAW
        Expected: Content-Type: #{HEADER_CONTENT_TYPE_PNG}
        Actual: Content-Type: #{content_type.nil? ? "nil" : ("\"" + content_type + "\"")}
        RAW
        return false
      end
      unless (x_frame_options = actual_res.headers["X-Frame-Options"]?) && x_frame_options == HEADER_X_FRAME_OPTIONS_DENY
        @message = <<-RAW
        Expected: X-Frame-Options: #{HEADER_X_FRAME_OPTIONS_DENY}
        Actual: X-Frame-Options: #{x_frame_options.nil? ? "nil" : ("\"" + x_frame_options + "\"")}
        RAW
        return false
      end
      # @todo should this be used on the html document,
      # or should it be used on the ugc files themselves?
      # for servers hosting untrusted (user uploaded) content
      unless (x_content_type_options = actual_res.headers["X-Content-Type-Options"]?) && x_content_type_options == HEADER_X_CONTENT_TYPE_OPTIONS_NOSNIFF
        @message = <<-RAW
        Expected: X-Content-Type-Options: #{HEADER_X_CONTENT_TYPE_OPTIONS_NOSNIFF}
        Actual: X-Content-Type-Options: #{x_content_type_options.nil? ? "nil" : ("\"" + x_content_type_options + "\"")}
        RAW
        return false
      end
      # tell browser to make xss even more not happen
      unless (x_xss_protection = actual_res.headers["X-XSS-Protection"]?) && x_xss_protection == HEADER_X_XSS_PROTECTION_MODE_BLOCK
        @message = <<-RAW
        Expected: X-XSS-Protection: #{HEADER_X_XSS_PROTECTION_MODE_BLOCK}
        Actual: X-XSS-Protection: #{x_xss_protection.nil? ? "nil" : ("\"" + x_xss_protection + "\"")}
        RAW
        return false
      end

      file = ::File.tempfile "actual_res_body" do |file|
        file << actual_res.body
      end
      # result = Iom::Php::ShellExec.shell_exec("tidy", ["-e", "-q", file.path])
      # pp result

      # ubuntu:
      # wget https://github.com/htacg/tidy-html5/releases/download/5.4.0/tidy-5.4.0-64bit.deb
      # sudo dpkg -i tidy-5.4.0-64bit.deb
      # @todo PNG validator

      return true
    end

    def failure_message(actual_res)
      @message
    end
  end
end
