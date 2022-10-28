require "json"

class ::Raven::Breadcrumb
  include JSON::Serializable

  def self.record(**opts) : ::Raven::Breadcrumb
    crumb = ::Raven::Breadcrumb.new(**opts)
    ::Raven.instance.breadcrumbs.record crumb
    crumb
  end
end
