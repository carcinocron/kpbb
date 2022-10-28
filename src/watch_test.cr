require "sentry"

sentry = Sentry::ProcessRunner.new(
  display_name: "spec",
  run_command: "crystal",
  build_command: "echo",
  run_args: ["spec", "--error-trace", "--fail-fast", ENV["TEST_ARGS"]?.presence].compact,
  build_args: ["rebuilding tests"] of String,
  files: ["./src/**/*.cr", "./src/views/**/*.ecr", "./spec/**/*.cr"],
  should_build: true,
  install_shards: false,
  colorize: true,
)

# spawn {
#   Sentry::ProcessRunner.new(
#     display_name:   "sass",
#     build_command:          "node_modules/.bin/sass",
#     run_command:            "node_modules/.bin/sass",
#     build_args:       ["./src/sass/main.sass:./public/css/one.css"],
#     run_args:       ["./src/sass/main.sass:./public/css/one.css"],
#     files: ["./src/sass/**/*.sass", "./src/sass/**/*.css"],
#     should_build: true,
#     install_shards: false,
#     colorize: true,
#   ).run
# }

sentry.run
