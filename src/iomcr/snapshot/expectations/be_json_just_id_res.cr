require "file"

module Iom::Spec
  struct JustIdFromJson
    include JSON::Serializable
  
    property id : Int64?
  end
  
  struct BeJsonJustIdResponseExpectation
    def initialize
      @expected_status_code = 200
      @expected_body = "{\"id\": Int64}"
    end

    def match(actual_res)
      body = JustIdFromJson.from_json(actual_res.body)
    
      unless body.id.nil?
        @expected_body = body.to_json
      end
      expected_value = <<-RAW
      #{@expected_status_code}
      Accept: application/json
      #{@expected_body}
      RAW
      actual_value = <<-RAW
      #{actual_res.status_code}
      Accept: #{actual_res.headers["Content-Type"]?}
      #{actual_res.body}
      RAW

      # For the case of comparing strings we want to make sure that two strings
      # are equal if their content is equal, but also their bytesize and size
      # should be equal. Otherwise, an incorrect bytesize or size was used
      # when creating them.
      if actual_value.is_a?(String) && expected_value.is_a?(String)
        actual_value == expected_value &&
          actual_value.bytesize == expected_value.bytesize &&
          actual_value.size == expected_value.size
      else
        actual_value == expected_value
      end
    end

    def failure_message(actual_res)
      expected_value = <<-RAW
      #{@expected_status_code}
      Accept: application/json
      #{Iom::Spec::BeJsonResponseExpectation.json_to_yml(@expected_body)}
      RAW
      actual_value = <<-RAW
      #{actual_res.status_code}
      Accept: #{actual_res.headers["Content-Type"]?}
      #{Iom::Spec::BeJsonResponseExpectation.json_to_yml(actual_res.body)}
      RAW

      # Check for the case of string equality when the content match
      # but not the bytesize or size.
      diff = ""
      files = [] of ::File
      begin
        files << ::File.tempfile "actual" do |file|
          file << actual_value+"\n"
        end
        files << ::File.tempfile "expected" do |file|
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

    def negative_failure_message(actual_value)
      "Expected: actual_value != #{@expected_value.inspect}\n     got: #{actual_value.inspect}"
    end

    def self.json_to_yml(value)
      begin
        YAML.dump(JSON.parse(value))
      rescue ex
        value
      end
    end
  end
end
