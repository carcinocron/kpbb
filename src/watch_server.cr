require "sentry"

sentry = Sentry::ProcessRunner.new(
  display_name: "server",
  build_command: "crystal build ./src/server.cr --error-trace",
  run_command: "./server",
  # build_args:     [] of String,
  # run_args:       [] of String,
  files: ["./src/**/*.cr", "./src/views/**/*.ecr"],
  should_build: true,
  install_shards: false,
  colorize: true,
)

# node_modules/.bin/tailwindcss --input assets/tailwindcss/app.css --ouput public/static/app.css --watch
# spawn {
#   Sentry::ProcessRunner.new(
#     display_name:   "tailwindcss",
#     build_command:          "node_modules/.bin/tailwindcss",
#     run_command:            "node_modules/.bin/tailwindcss",
#     build_args:       ["--input", "./assets/tailwindcss/app.css", "--output", "./public/css/app.css"],
#     run_args:         ["--input", "./assets/tailwindcss/app.css", "--output", "./public/css/app.css", "--watch"],
#     files: ["./tailwind.config.js", "postcss.config.js"],
#     should_build: true,
#     install_shards: false,
#     colorize: true,
#   ).run
# }

sentry.run
