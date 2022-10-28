require "../spec_helper"
require "../../src/markdown"

describe "Email::PartialMask" do
  it "does not crash on invalid email address" do
    masked = Kpbb::Email.partial_mask "fredymercurygmail.com"
    masked.should eq "fredymercurygmail.com"

    masked = Kpbb::Email.partial_mask "fredymercury@gmailcom"
    masked.should eq "fredymercury@gmailcom"
  end

  it "partially masks a valid email address" do
    masked = Kpbb::Email.partial_mask "fredymercury@gmail.com"
    masked.should eq "fr********ry@gm*il.***"

    masked = Kpbb::Email.partial_mask "fredymercury@yahoo.com"
    masked.should eq "fr********ry@ya*oo.***"

    masked = Kpbb::Email.partial_mask "fredymercury@example.co.uk"
    masked.should eq "fr********ry@ex*****.co.**"

    # not useful for short email addresses
    masked = Kpbb::Email.partial_mask "f@a.b"
    masked.should eq "f@a.*"

    masked = Kpbb::Email.partial_mask "fredy@mydomain.com"
    masked.should eq "fr*dy@my****in.***"
  end

  it "always reveals some key symbols" do
    masked = Kpbb::Email.partial_mask "fredy.mercury@gmail.com"
    masked.should eq "fr***.*****ry@gm*il.***"

    masked = Kpbb::Email.partial_mask "fredy@mercury@gmail.com"
    masked.should eq "fr***@*****ry@gm*il.***"

    masked = Kpbb::Email.partial_mask "fredy+mercury@gmail.com"
    masked.should eq "fr***+*****ry@gm*il.***"
  end
end
