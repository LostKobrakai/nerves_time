defmodule Nerves.NTP.Worker do
  use GenServer
  alias Nerves.NTP.OutputParser
  require Logger

  @default_ntpd_path "/usr/sbin/ntpd"
  @default_ntp_servers [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
    "2.pool.ntp.org",
    "3.pool.ntp.org"
  ]

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_args) do
    Logger.debug("Starting Worker")
    GenServer.start_link(__MODULE__, :ok)
  end

  @spec init(any()) :: {:ok, any()}
  def init(_args) do
    ntpd_path = Application.get_env(:nerves_ntp, :ntpd, @default_ntpd_path)
    servers = Application.get_env(:nerves_ntp, :servers, @default_ntp_servers)
    set_time = Application.get_env(:nerves_ntp, :set_time, true)
    ntpd_script_path = Application.app_dir(:nerves_ntp, "priv/ntpd_script")

    args =
      [ntpd_path, "-n", "-d", "-S", ntpd_script_path] ++
        server_args(servers) ++ set_time_args(set_time)

    Logger.debug("Running ntp as: #{inspect(args)}")

    # Call ntpd using muontrap. Muontrap will kill ntpd if this GenServer
    # crashes.
    ntpd =
      Port.open({:spawn_executable, MuonTrap.muontrap_path()}, [
        {:args, ["--" | args]},
        :exit_status,
        :use_stdio,
        :binary,
        {:line, 2048},
        :stderr_to_stdout
      ])

    {:ok, ntpd}
  end

  def handle_info({_, {:exit_status, code}}, _state) do
    Logger.error("ntpd exited with code: #{code}")
    # ntp exited so we will try to restart it after 10 sek
    # Port.close(state) // not required... as port is already closed
    pause_and_die()
  end

  def handle_info({_, {:data, {:eol, message}}}, port) do
    # Logger.debug "Received data from port #{message}"
    result = OutputParser.parse(message)
    IO.inspect(result)

    {:noreply, port}
  end

  def handle_info(msg, state) do
    Logger.debug("#{inspect(msg)}")
    Logger.debug("#{inspect(state)}")
    {:noreply, state}
  end

  defp pause_and_die do
    Process.sleep(10_000)
    {:stop, :shutdown, nil}
  end

  defp server_args(servers) do
    Enum.flat_map(servers, fn s -> ["-p", s] end)
  end

  defp set_time_args(true), do: []
  defp set_time_args(false), do: ["-w"]
end
