require "file"

module Iom::Spec
  struct MultilineEqualExpectation(T)
    def initialize(@expected_value : T)
    end

    def match(actual_value)
      expected_value = @expected_value

      # For the case of comparing strings we want to make sure that two strings
      # are equal if their content is equal, but also their bytesize and size
      # should be equal. Otherwise, an incorrect bytesize or size was used
      # when creating them.
      if actual_value.is_a?(String) && expected_value.is_a?(String)
        actual_value == expected_value &&
          actual_value.bytesize == expected_value.bytesize &&
          actual_value.size == expected_value.size
      else
        actual_value == @expected_value
      end
    end

    def failure_message(actual_value)
      expected_value = @expected_value

      # Check for the case of string equality when the content match
      # but not the bytesize or size.
      if actual_value.is_a?(String) &&
        expected_value.is_a?(String) &&
        actual_value == expected_value
        if actual_value.bytesize != expected_value.bytesize
          return <<-MSG
            Expected bytesize: #{expected_value.bytesize}
                got bytesize: #{actual_value.bytesize}
            MSG
        end

        return <<-MSG
          Expected size: #{expected_value.size}
              got size: #{actual_value.size}
          MSG
      else
        diff = ""
        files = [] of File
        begin
          files << File.tempfile "actual" do |file|
            file << actual_value+"\n"
          end
          files << File.tempfile "expected" do |file|
            file << expected_value+"\n"
          end
          output = IO::Memory.new
          exit_code = Process.run("diff", args: [
            "--unified",
            # "-w",
            files[0].path,
            files[1].path,
          ], output: output, error: output)
      
          diff = output.to_s
        ensure
          files.each do |file|
            file.close
            file.delete
          end
        end

        "--- Expected\n+++ Actual\n#{diff}"
      end
    end

    def negative_failure_message(actual_value)
      "Expected: actual_value != #{@expected_value.inspect}\n     got: #{actual_value.inspect}"
    end
  end
end
