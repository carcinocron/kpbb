unless IS_PRODUCTION
  get "/ravenhandlertest-route1-500" do |env|
    raise "test1"
  end
end
