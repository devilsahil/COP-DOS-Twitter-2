defmodule Twitter.EctoRepo do
	
  use Ecto.Repo,otp_app: :twitter

  def init(_,options) do
    {:ok, Keyword.put(options,:url,System.get_env("DATABASE_URL"))}
  end
end
