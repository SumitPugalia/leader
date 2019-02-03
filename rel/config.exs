use Mix.Releases.Config,
  default_release: :default,
  default_environment: :prod

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"leaderconnect"
  set vm_args: "rel/vm.args"
end

release :leader do

  set overlays: [
        {:copy, "rel/config/config.exs", "etc/config.exs"}
      ]
      
  set config_providers: [
        {Mix.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
      ]
end
