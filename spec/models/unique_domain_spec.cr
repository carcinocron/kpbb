require "../spec_helper"

describe "Models::Kpbb::Domain::Unique" do
  it "saves domains" do
    empty_db
    domain1 = Kpbb::Domain.save! "example1.com"
    domain2 = Kpbb::Domain.save! "example2.com"
    domain1.should be < domain2
  end

  it "deduplicates domains on save" do
    empty_db
    domain1 = Kpbb::Domain.save! "example.com"
    domain2 = Kpbb::Domain.save! "example.com"
    domain1.should eq domain2
  end
end
