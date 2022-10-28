require "../spec_helper"
require "../../src/markdown"

describe "Markdown::Html" do
  it "escapes script tags" do
    body_md = <<-MD
      <script>console.log("spooku")</script>
      MD

    Markdown.to_html(body_md).should eq "\n"
  end

  it "renders an external href tag" do
    body_md = <<-MD
      [friendship](https://www.google.com/)
      MD

    Markdown.to_html(body_md).should eq <<-MD
    <p><a href="https://www.google.com/" target="_blank" rel="nofollow ugc">friendship</a></p>\n
    MD
  end

  it "renders an internal href tag" do
    body_md = <<-MD
      [friendship](/about-friendship)
      MD

    Markdown.to_html(body_md).should eq <<-MD
    <p><a href="/about-friendship">friendship</a></p>\n
    MD
  end

  it "renders an internal href tag missing initial slash" do
    body_md = <<-MD
      [friendship](about-friendship)
      MD

    Markdown.to_html(body_md).should eq <<-MD
    <p><a href="about-friendship">friendship</a></p>\n
    MD
  end

  it "renders an external href that was uppercased" do
    body_md = <<-MD
      [example](HTTP://EXAMPLE.COM)
      MD

    Markdown.to_html(body_md).should eq <<-MD
    <p><a href="HTTP://EXAMPLE.COM" target="_blank" rel="nofollow ugc">example</a></p>\n
    MD
  end

  it "renders an external href that was ftp protocol" do
    body_md = <<-MD
      [ftp example](ftp://example.com/file.txt)
      MD

    Markdown.to_html(body_md).should eq <<-MD
    <p><a href="ftp://example.com/file.txt" target="_blank" rel="nofollow ugc">ftp example</a></p>\n
    MD
  end

  it "renders an external href that was mailto protocol" do
    body_md = <<-MD
      [mailto example](mailto:name@example.com)
      MD

    Markdown.to_html(body_md).should eq <<-MD
    <p><a href="mailto:name@example.com" target="_blank" rel="nofollow ugc">mailto example</a></p>\n
    MD
  end

  it "renders an external href that was tel protocol" do
    body_md = <<-MD
      [tel example](tel:123-456-7890)
      MD

    Markdown.to_html(body_md).should eq <<-MD
    <p><a href="tel:123-456-7890" target="_blank" rel="nofollow ugc">tel example</a></p>\n
    MD
  end

  it "renders an external href that was protocol-relative absolute" do
    body_md = <<-MD
      [protocol-relative absolute](//example.com/)
      MD

    Markdown.to_html(body_md).should eq <<-MD
    <p><a href="//example.com/" target="_blank" rel="nofollow ugc">protocol-relative absolute</a></p>\n
    MD
  end
end
