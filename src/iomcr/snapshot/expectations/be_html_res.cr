require "file"
require "php-shell-exec"

private HEADER_CONTENT_TYPE_HTML              = "text/html; charset=utf-8"
private HEADER_X_FRAME_OPTIONS_DENY           = "DENY"
private HEADER_X_CONTENT_TYPE_OPTIONS_NOSNIFF = "nosniff"
private HEADER_X_XSS_PROTECTION_MODE_BLOCK    = "1; mode=block"

module Iom::Spec
  struct BeHtmlResponseExpectation
    def initialize
      @needle = "<!DOCTYPE html>\n<html lang=\"en\">"
    end

    def match(actual_res)
      unless actual_res.body.starts_with? @needle
        @message = <<-RAW
        Expected: starts with "#{@needle}"
        Actual: starts with "#{actual_res.body[0, 128]}"
        RAW
        return false
      end
      unless (content_type = actual_res.headers["Content-Type"]?) && content_type == HEADER_CONTENT_TYPE_HTML
        @message = <<-RAW
        Expected: Content-Type: #{HEADER_CONTENT_TYPE_HTML}
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
      # @todo HTML validator

      return true

      htmllint_result = Iom::Php::ShellExec.shell_exec("./node_modules/.bin/htmllint", [
        file.path,
      ])

      if htmllint_result.exit_code != 0
        body_lines = actual_res.body.split "\n"
        ln_gutter = body_lines.size.to_s.size || 1

        context_leading = 5
        context_trailing = 5
        data = Array(String).new
        htmllint_result.stdout.split("\n").map { |v| v.strip.presence }.compact!.each do |text|
          text = text.not_nil!
          data << ""
          data << (" - -" * 20)
          data << ""
          if md = text.not_nil!.match(/:\sline\s(\d+),\scol\s(\d+),\s*(.*)/)
            if (line = md[1]?.try(&.to_i32?)) && (col = md[2]?.try(&.to_i32?)) && (msg = md[3]?.presence)
              line_index = line - 1
              (1..context_leading).reverse_each do |offset|
                if s = body_lines[(line_index - offset)]?
                  data << "#{line - offset}: ".rjust(ln_gutter) + s
                end
              end
              data << "#{line}: ".rjust(ln_gutter) + (body_lines[line_index]? || "Error: line not found")
              if col > 0
                data << (" " * (col - 1)) + "^"
                data << (" " * (col - 1)) + text
              else
                data << "^"
                data << " ".rjust(ln_gutter) + text
              end
              (1..context_trailing).each do |offset|
                if s = body_lines[(line_index + offset)]?
                  data << "#{line + offset}: ".rjust(ln_gutter) + s
                end
              end
              data << ""
            end
          end
        end
        # pp data
        # pp htmllint_result
        @message = data.join "\n"
        return false
      end

      return true
    end

    def failure_message(actual_res)
      @message
    end
  end
end
