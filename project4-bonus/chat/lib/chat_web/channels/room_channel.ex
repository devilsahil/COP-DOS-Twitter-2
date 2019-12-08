defmodule ChatWeb.RoomChannel do
  use ChatWeb, :channel
  @userID -1

  def join("room:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  def handle_in("shout", payload, socket) do
    IO.inspect("Starting  Registration")
   # payload[:name] = Client.start_link("1",5,5,5,false)
    IO.inspect("Ending  Registration")
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def registrationConfirmation(userId) do
    userID = userId
    IO.inspect("Coming from Chatter")
    IO.inspect(userID)
    IO.inspect("Coming from Chatter End")
  end

  # def handle_in("login", payload, socket) do
  #   IO.inspect("Starting  Login")
  #   Client.login(@userID)
  #   IO.inspect(:ets.lookup(:userTable, @userID))
  #   IO.inspect("Ending  Login")
  #   broadcast socket, "shout", payload
  #   {:noreply, socket}
  # end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
