require "file"
require "file_utils"

module Iom::Spec
  struct JsonSnapshotExpectation
    @@snapshot_dir : String = "spec/__snapshots__/"
    snapshot_name : String
    snap_path : String

    def initialize(@snapshot_name : String)
      filename = "#{@snapshot_name.gsub(" ", "_")}.snap"
      @snap_path = File.join(@@snapshot_dir, filename)
    end

    def match(actual_value : String)
      @actual_value = actual_value
      FileUtils.mkdir_p(File.dirname(@snap_path)) unless Dir.exists?(File.dirname(@snap_path))
      if File.exists?(@snap_path)
        # file = File.new(@snap_path)
        @expected_value = File.read @snap_path
        # file.close

        # For the case of comparing strings we want to make sure that two strings
        # are equal if their content is equal, but also their bytesize and size
        # should be equal. Otherwise, an incorrect bytesize or size was used
        # when creating them.
        if actual_value.is_a?(String) && @expected_value.is_a?(String)
          actual_value == @expected_value &&
            actual_value.not_nil!.bytesize == @expected_value.not_nil!.bytesize &&
            actual_value.not_nil!.size == @expected_value.not_nil!.size
        else
          actual_value == @expected_value
        end
      else
        # RSpec.configuration.reporter.message "Generate #{@snap_path}"
        puts "\n"
        puts "Generate #{@snap_path}"
        puts "\n"
        # file = File.new(@snap_path, "w+")
        File.write(@snap_path, @actual_value)
        # file.close
        true
      end
    end

    # files should always have 2 elements
    # get json_reformat from:
    #     sudo apt install yajl-tools
    def self.before_diff (files : Array(File))
      files.each do |file|
        output = IO::Memory.new
        cmd = "{ rm #{file.path} ; json_reformat > #{file.path} ; } < #{file.path}"
        status = Process.run(cmd, output: output, error: output, shell: true)

        if status.exit_code != 0
          result = {"exit_code"=>status.exit_code,"cmd"=>cmd,"output"=>output.to_s}
          puts result.inspect
          raise result.inspect
        end
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
          files << File.tempfile "expected" do |file|
            file << (expected_value || "") +"\n"
          end
          files << File.tempfile "actual" do |file|
            file << (actual_value || "") +"\n"
          end

          Iom::Spec::JsonSnapshotExpectation.before_diff files

          output = IO::Memory.new
          exit_code = Process.run("diff", args: [
            "--unified",
            "-w",
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

        "snapshot: #{@snap_path}\n--- Expected\n+++ Actual\n#{diff}"
      end
    end

    def negative_failure_message(actual_value)
      "Expected: actual_value != #{@expected_value.inspect}\n     got: #{actual_value.inspect}"
    end
  end
end
