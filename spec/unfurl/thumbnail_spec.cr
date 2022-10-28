require "../spec_helper"
require "../../src/markdown"

describe "Unfurl::thumbnail" do
  it "does not crash on invalid email address" do
    value = Iom::Unfurl::Metadata.from_json "{}"
    value.thumbnail.should be_nil

    expected_thumbnail = "https://www.example.com/something.png"
    value = Iom::Unfurl::Metadata.from_json ({
      :open_graph => {
        :images => [
          {:url => expected_thumbnail},
        ],
      },
    }.to_json)
    value.thumbnail.should eq expected_thumbnail

    value = Iom::Unfurl::Metadata.from_json ({
      :twitter_card => {
        :images => [
          {:url => expected_thumbnail},
        ],
      },
    }.to_json)
    value.thumbnail.should eq expected_thumbnail

    value = Iom::Unfurl::Metadata.from_json ({
      :oEmbed => {
        :thumbnails => [
          {:url => expected_thumbnail},
        ],
      },
    }.to_json)
    value.thumbnail.should eq expected_thumbnail
  end

  it "prefers open_graph, then twitter_card, then oEmbed" do
    expected_thumbnail = "https://www.example.com/something.png"
    value = Iom::Unfurl::Metadata.from_json ({
      :open_graph => {
        :images => [
          {:url => expected_thumbnail},
        ],
      },
      :twitter_card => {
        :images => [
          {:url => "https://wrong.com/blah.png"},
        ],
      },
      :oEmbed => {
        :thumbnails => [
          {:url => "https://wrong.com/foobar.png"},
        ],
      },
    }.to_json)
    value.thumbnail.should eq expected_thumbnail

    value = Iom::Unfurl::Metadata.from_json ({
      :twitter_card => {
        :images => [
          {:url => expected_thumbnail},
        ],
      },
      :oEmbed => {
        :thumbnails => [
          {:url => "https://wrong.com/foobar.png"},
        ],
      },
    }.to_json)
    value.thumbnail.should eq expected_thumbnail
  end

  it "does not early return on null or empty string values" do
    expected_thumbnail = "https://www.example.com/something.png"
    value = Iom::Unfurl::Metadata.from_json ({
      :open_graph => {
        :images => [
          {:url => ""},
        ],
      },
      :twitter_card => {
        :images => [
          {:url => nil},
        ],
      },
      :oEmbed => {
        :thumbnails => [
          {:url => expected_thumbnail},
        ],
      },
    }.to_json)
    value.thumbnail.should eq expected_thumbnail
  end
end
