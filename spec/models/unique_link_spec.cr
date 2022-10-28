require "../spec_helper"

describe "Models::Kpbb::Link::Unique" do
  it "deduplicates links on save" do
    empty_db
    link1 = Kpbb::Link.save! "http://www.example.com/awesome"
    link2 = Kpbb::Link.save! "http://www.example.com/awesome"
    link1.should eq link2

    # link = Kpbb::Link.find! post.link_id.not_nil!
    # link.url.should eq url
    # link.domain_id.should be_truthy

    # domain = Kpbb::Domain.find! link.domain_id
    # domain.domain.should be_truthy
  end

  it "deduplicates domains on save" do
    empty_db
    link1 = Kpbb::Link.save! "http://d1.com/path1"
    link2 = Kpbb::Link.save! "http://d2.com/other-path"
    link1.should be < link2
  end
end
