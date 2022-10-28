require "../spec_helper"

describe "Cron::EnabledDisabled" do
  it "can be disabled" do
    empty_db
    Kpbb::SettingKeyValue.fetch.enable_cron?.should be_true
    Kpbb::SettingKeyValue.cache.enable_cron = false
    Kpbb::SettingKeyValue.cache.enable_cron?.should be_false
    Kpbb::SettingKeyValue.fetch.enable_cron?.should be_false
    Kpbb::SettingKeyValue.cache.enable_cron = true
    Kpbb::SettingKeyValue.cache.enable_cron?.should be_true
    Kpbb::SettingKeyValue.fetch.enable_cron?.should be_true
  end
end
