module Raven
  class Context
    # the original library runs uname which
    # apparently can't be ran in an unpriviliged alpine docker container
    class_getter os_context : AnyHash::JSON do
      {
        exec: ENV["RAVEN_OS_CONTEXT_EXEC"]?,
        # name:           Raven.sys_command("uname -s"),
        # version:        Raven.sys_command("uname -v"),
        # build:          Raven.sys_command("uname -r"),
        # kernel_version: Raven.sys_command("uname -a") || Raven.sys_command("ver"), # windows
      }.to_any_json
    end
  end
end