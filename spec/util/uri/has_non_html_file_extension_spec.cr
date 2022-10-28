require "../../spec_helper"

describe "URI::has_non_html_file_extension" do
  it "returns correct result" do
    value = URI.parse("https://www.example.com/fun.html")
    value.has_non_html_file_extension?.should be_false
    value.extension.should eq "html"
    value = URI.parse("https://www.example.com/fun.htm")
    value.has_non_html_file_extension?.should be_false
    value.extension.should eq "htm"
    value = URI.parse("https://www.example.com/fun.html5")
    value.has_non_html_file_extension?.should be_false
    value.extension.should eq "html5"
    value = URI.parse("https://www.example.com/fun")
    value.has_non_html_file_extension?.should be_false
    value.extension.should eq nil

    value = URI.parse("https://www.example.com/fun.pdf")
    value.has_non_html_file_extension?.should be_true
    value.extension.should eq "pdf"
    value = URI.parse("https://www.example.com/fun.jpeg")
    value.has_non_html_file_extension?.should be_true
    value.extension.should eq "jpeg"
    value = URI.parse("https://www.example.com/fun.json")
    value.has_non_html_file_extension?.should be_true
    value.extension.should eq "json"
  end
end
