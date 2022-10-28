ENV["PORT"] ||= "5000"
ENV["PG_URL"] ||= "postgresql://kpbb:kpbb@localhost:5433/kpbb?sslmode=require"
ENV["SENTRY_DSN"] ||= "http://skjdfhsjdlflsdkjfklsd:bbbatf@localhost:53080/1"
ENV["COOKIE_SECRET"] ||= "my_super_secret"
ENV["PASSWORD_COST"] ||= ((ENV["KEMAL_ENV"] == "testing") ? 4 : 11).to_s
ENV["APP_NAME"] ||= "kpbb"

IS_PRODUCTION = ENV["KEMAL_ENV"] == "production"
IS_PORT_80    = ENV["PORT"] == 80 || ENV["PORT"] == "80"
BASE_URL      = if IS_PORT_80
                  "https://#{ENV["APP_DOMAIN"]}"
                else
                  "https://#{ENV["APP_DOMAIN"]}:#{ENV["PORT"]}"
                end
