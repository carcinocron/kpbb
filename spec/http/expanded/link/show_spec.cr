require "../../../spec_helper"

describe "Http::Expanded::Links::Show" do
  it "shows DNE" do
    empty_db

    req = HTTP::Request.new("GET", "/expanded/links/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html

    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/expanded/links/50", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 404
    res.should be_html
  end

  it "shows active" do
    empty_db

    url = "http://www.example.com/page1"
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    link_id = Kpbb::Link.save!(url, domain_id, active: true)
    req = HTTP::Request.new("GET", "/expanded/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html_fragment
    res.body.strip.should eq "No Thumbnail"

    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/expanded/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html_fragment
    res.body.strip.should eq "No Thumbnail"
  end

  it "shows not active" do
    empty_db

    url = "http://www.example.com/page1"
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    link_id = Kpbb::Link.save!(url, domain_id, active: false)
    req = HTTP::Request.new("GET", "/expanded/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.should be_redirect_login

    user1 = TestUser.new(handle: "username1")

    req = user1.request("GET", "/expanded/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 403
    res.should be_html

    user2 = TestUser.new(handle: "username2", rank: 1)

    req = user2.request("GET", "/expanded/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html_fragment
    res.body.strip.should eq "No Thumbnail"
  end

  it "shows active youtube video" do
    empty_db

    url = "https://www.youtube.com/watch?v=oHg5SJYRHA0"
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    link_id = Kpbb::Link.save!(url, domain_id, active: true, meta: ({
      :youtube_id => "oHg5SJYRHA0",
    }).to_json)
    req = HTTP::Request.new("GET", "/expanded/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html_fragment
    res.body.should match_snapshot "Http/Expanded/Links/Show/shows active youtube video"
  end

  it "shows active link with unfurl open_graph thumbnail" do
    empty_db

    url = "https://www.example.com/voldemort"
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    link_id = Kpbb::Link.save!(url, domain_id, active: true, meta: ({
      :unfurl => {
        :open_graph => {
          :images => [
            {:url => "https://www.example.com/voldemort-thumb.png",
             :width => 400, :height => 600},
          ],
        },
      },
    }).to_json)
    req = HTTP::Request.new("GET", "/expanded/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html_fragment
    res.body.should match_snapshot "Http/Expanded/Links/Show/shows shows active link with unfurl open_graph thumbnail"
  end

  it "shows active link with unfurl open_graph thumbnail with bigger thumbnail" do
    empty_db

    url = "https://www.example.com/voldemort"
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    link_id = Kpbb::Link.save!(url, domain_id, active: true, meta: ({
      :unfurl => {
        :open_graph => {
          :images => [
            {:url => "https://www.example.com/voldemort-thumb.png",
             :width => 1600, :height => 1200},
          ],
        },
      },
    }).to_json)
    req = HTTP::Request.new("GET", "/expanded/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html_fragment
    res.body.should match_snapshot "Http/Expanded/Links/Show/shows shows active link with unfurl open_graph thumbnail with bigger thumbnail"
  end

  it "shows active link with unfurl open_graph thumbnail where width and height are string" do
    empty_db

    url = "https://www.example.com/voldemort"
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    link_id = Kpbb::Link.save!(url, domain_id, active: true, meta: ({
      :unfurl => {
        :open_graph => {
          :images => [
            {:url => "https://www.example.com/voldemort-thumb.png",
             :width => "400", :height => "600"},
          ],
        },
      },
    }).to_json)
    req = HTTP::Request.new("GET", "/expanded/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html_fragment
    res.body.should match_snapshot "Http/Expanded/Links/Show/shows shows active link with unfurl open_graph thumbnail where width and height are string"
  end

  it "shows active link with unfurl oEmbed" do
    empty_db

    url = "https://www.example.com/voldemort"
    domain_id = Kpbb::Domain.save!(URI.parse(url).host.not_nil!.downcase)
    link_id = Kpbb::Link.save!(url, domain_id, active: true, meta: ({
      :unfurl => {
        :oEmbed => {
          :thumbnails => [
            {:url => "https://www.example.com/voldemort-thumb.png",
             :width => 400, :height => 600},
          ],
        },
      },
    }).to_json)
    req = HTTP::Request.new("GET", "/expanded/links/#{link_id.to_b62}", default_browser_get_headers, "")
    res = process_request req
    res.status_code.should eq 200
    res.should be_html_fragment
    res.body.should match_snapshot "Http/Expanded/Links/Show/shows shows active link with unfurl open_graph thumbnail where width and height are string"
  end
end
