require "markd"

class Kpbb::CustomRenderer < Markd::HTMLRenderer
  @@is_absolute_url = /^(?:[a-z]+:)?\/\//

  def link(node : Markd::Node, entering : Bool)
    if entering
      attrs = attrs(node)
      unless @options.safe? && potentially_unsafe(destination = node.data["destination"].as(String).try(&.strip))
        unless (destination = destination.presence).nil?
          attrs ||= {} of String => String
          attrs["href"] = escape(destination)
        end
      end

      if attrs && ((href = attrs["href"]?) && href.is_a?(String))
        if href.nil?
          # pass
        elsif href.includes?(":") || href.starts_with?("//")
          # includes ":" is a dumb heuristic,
          # but all we have to do is never allow : in urls
          # and then that's fine
          # and now 99+% of cases don't use a regex
          attrs["target"] = "_blank"
          attrs["rel"] = "nofollow ugc"
        elsif href.downcase =~ @@is_absolute_url
          attrs["target"] = "_blank"
          attrs["rel"] = "nofollow ugc"
        end
      end

      if (title = node.data["title"].as(String)) && !title.empty?
        attrs ||= {} of String => String
        attrs["title"] = escape(title)
      end

      tag("a", attrs)
    else
      tag("a", end_tag: true)
    end
  end
end

module Markdown
  @@options = Markd::Options.new(
    prettyprint: true,
    # gfm: true, # when supported
    # base_url: @todo
    # source_pos: true,
    smart: true,
    safe: true)

  def self.to_html(md : String) : String
    document = Markd::Parser.parse(md, @@options)
    renderer = Kpbb::CustomRenderer.new(@@options)
    renderer.render(document)
      .gsub "<!-- raw HTML omitted -->", ""
  end
end
