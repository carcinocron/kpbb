# require "spec"
require "xml"
require "yaml"
require "json"
require "spec-kemal"
require "../src/server"
require "../src/iomcr/snapshot/snapshot"
require "./util/db/*"
require "./util/request/*"
require "./util/models/*"
require "./util/assertions/*"

Spec.before_each do
  ::Raven::BreadcrumbBuffer.clear!
end

Spec.after_each do
  #   Kemal.config.clear
  #   Kemal::RouteHandler::INSTANCE.cached_routes = Hash(String, Radix::Result(Kemal::Route)).new
  #   Kemal::RouteHandler::INSTANCE.routes.clear
  #   Kemal::RouteHandler::INSTANCE.cached_routes.clear
  #   Kemal::RouteHandler::INSTANCE.routes = Radix::Tree(Kemal::Route).new
end

struct IdFromJson
  include JSON::Serializable

  property id : Int64
end

macro pj2y(expression)
  printf "\n"+YAML.dump(JSON.parse({{expression}}))+"\n"
end

# use jq to change timestamps to their types
# so snapshots are usable
Iom::Spec::JsonAsYamlSnapshotExpectation.set_jq <<-JQ
walk(
  if type == "object" then
    if has("created_at") then
      .created_at="snapshot_type_"+(.created_at|type)
    else . end
    |
    if has("updated_at") then
      .updated_at="snapshot_type_"+(.updated_at|type)
    else . end
    |
    if has("published_at") then
      .published_at="snapshot_type_"+(.published_at|type)
    else . end
  else . end
)
JQ

# tried this, no performance benefit seen
# GC.collect
# GC.disable
