defmodule MAIN do
    def main(args) do
      args |> parse_args |> delegate
    end

    defp parse_args(args) do
      {_,parameters,_} = OptionParser.parse(args)
      parameters
    end

    def delegate(parameters) do
        # pid = spawn(fn -> Server.start_link() end)
        # :global.register_name(:TwitterServer, pid)
        :global.sync()
        numClients = String.to_integer(Enum.at(parameters,0))
        {:ok, server_pid} = Server.start_link(numClients)
        numMessages = String.to_integer(Enum.at(parameters,1))
        disconnectClients = 30
        clientsToDisconnect = disconnectClients * (0.01) * numClients
        :ets.new(:mainregistry, [:set, :public, :named_table])

        start_time = System.system_time(:millisecond)

        createUsers(1,numClients, numMessages)
        simulate_disconnection(numClients,clientsToDisconnect, numClients)
    end

    def createUsers(count,noOfClients, numMessages) do
        userName = Integer.to_string(count)
        noOfTweets = round(Float.floor(noOfClients/count))
        noToSubscribe = round(Float.floor(noOfClients/(noOfClients-count+1))) - 1
        pid = spawn(fn -> Client.start_link(userName,noOfTweets,noToSubscribe, noOfClients, false) end)
        :ets.insert(:mainregistry, {userName, pid})
        if (count != noOfClients) do createUsers(count+1,noOfClients,numMessages) end
    end

    def simulate_disconnection(numClients,clientsToDisconnect, noOfClients) do
        Process.sleep(1000)
        disconnectList = handle_disconnection(numClients,clientsToDisconnect,0,[])
        Process.sleep(1000)
        Enum.each disconnectList, fn userName -> 
            count = String.to_integer(userName)
            noOfTweets = round(Float.floor(noOfClients/count))
            noToSubscribe = round(Float.floor(noOfClients/(noOfClients-count+1))) - 1
            pid = spawn(fn -> Client.start_link(userName,noOfTweets,noToSubscribe, noOfClients, true) end)
            :ets.insert(:mainregistry, {userName, pid})
        end
        simulate_disconnection(numClients,clientsToDisconnect, noOfClients)
    end

    def handle_disconnection(numClients,clientsToDisconnect,clientsDisconnected,disconnectList) do
        if clientsDisconnected < clientsToDisconnect do
            disconnectClient = :rand.uniform(numClients)
            disconnectClientId = whereis(Integer.to_string(disconnectClient))
            if disconnectClientId != nil do
                userId = Integer.to_string(disconnectClient)
                disconnectList = [userId | disconnectList]
                GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:userDeletion,userId})
                :ets.insert(:mainregistry, {userId, nil})
                Process.exit(disconnectClientId,:kill)
                IO.puts "Simulator :- User #{userId} has been disconnected"
                handle_disconnection(numClients,clientsToDisconnect,clientsDisconnected+1,disconnectList)
            else
                handle_disconnection(numClients,clientsToDisconnect,clientsDisconnected,disconnectList)
            end
        else
            disconnectList
        end
    end

    def whereis(userId) do
        [tup] = :ets.lookup(:mainregistry, userId)
        elem(tup, 1)
    end
end
