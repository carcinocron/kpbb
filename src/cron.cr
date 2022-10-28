require "./env"
require "./logging"
require "kemal"
require "webslug"
require "php-shell-exec"
require "base62"
# require "./kemal_patch"
require "./concern/**"
require "./util/model"
require "./util/model_url"
require "./orm/**"
require "./util/**"
require "./mask/**"
require "./db"
require "./s3"
require "./youtube"
require "./twitter"
require "./unfurl"
require "./thumbnail"
require "./policies/gate"
require "./session"
require "./view_context"
require "raven"
# require "helmet"
# require "./page"
require "./themes"
require "./channelaction"
require "./cron/index"
require "./iomcr/file/filetype"
require "./iomcr/url_abbr/url_abbr"
require "./headers"
require "./markdown"
require "./request/**"
require "./request/loginuser"
require "./view"
require "./ecr"
require "./raven/*"

::Raven.configure do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.current_environment = ENV["KEMAL_ENV"]
end

require "cron_scheduler"

macro run_subroutines(subroutines)
  {% for sr in subroutines %}
    begin
      elapsed_time = Time.measure {
        {{sr}}.run(minute: start_of_minute)
      }
      bc = ::Raven::Breadcrumb.record(
        data: ({
          :subroutine => "{{sr}}",
          :elapsed_time => "#{elapsed_time.milliseconds}ms",
        }),
        category: "cron.subroutine")
      Log.info { bc.to_json }
    rescue ex
      ::Raven.capture ex
      Log.error { ex }
    end
  {% end %}
end

def cron1(minute : Time) : Nil
  start_of_minute = minute.at_beginning_of_minute
  now = Time.utc

  ::Raven::BreadcrumbBuffer.clear!
  bc = ::Raven::Breadcrumb.record(
    data: {:start_of_minute => start_of_minute, :now => now},
    category: "cron.start")
  Log.info { bc.to_json }

  unless Kpbb::SettingKeyValue.fetch.enable_cron?
    done_at = Time.utc
    bc = ::Raven::Breadcrumb.record(
      data: {:done_at => done_at, :duration => "#{(done_at - now).milliseconds} ms", :cron_disabled => true},
      category: "cron.done")
    Log.info { bc.to_json }
  else
    run_subroutines([
      Kpbb::Cron::ChannelJob,
      Kpbb::Cron::RecentLink,
      Kpbb::Cron::Webhook::Inbound::Payload,
      Kpbb::Cron::Feed::Inbound::Endpoint::Fetch,
      Kpbb::Cron::Feed::Inbound::Payload::Fetch,
      Kpbb::Cron::RecentYoutubeVideos,
      Kpbb::Cron::RecentYoutubeChannels,
      Kpbb::Cron::RecentLinkAbbr::Youtube,
    ])

    done_at = Time.utc
    bc = ::Raven::Breadcrumb.record(
      data: {:done_at => done_at, :duration => "#{(done_at - now).milliseconds} ms"},
      category: "cron.done")
    Log.info { bc.to_json }
  end
end

if ENV["CRON_ONCE"]?
  cron1 Time.utc
  exit 0
else
  CronScheduler.define do
    # at("* 0,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23 * * *") { cron1 Time.utc }
    # at("*/5 1,2,3,4,5,6 * * *") { cron1 Time.utc } # run less often at night
    # at("* 0,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23 * * *") { cron1 Time.utc }
    at("* * * * *") { cron1 Time.utc } # run once per minute
  end

  Log.info { "Cron started" }

  sleep
end
