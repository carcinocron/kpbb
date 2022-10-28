require "../spec_helper"

describe "Models::Kpbb::Tag::Unique" do
  it "saves tags" do
    empty_db
    tag1 = Kpbb::Tag.save! "example1"
    tag2 = Kpbb::Tag.save! "example2"
    tag1.id.should be < tag2.id
  end

  it "deduplicates tags on save" do
    empty_db
    tag1 = Kpbb::Tag.save! "example"
    tag2 = Kpbb::Tag.save! "example"
    tag1.id.should eq tag2.id
  end
end
