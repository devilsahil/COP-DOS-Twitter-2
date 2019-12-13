defmodule Simulation do

    use Phoenix.ChannelTest
    @endpoint TwitterWeb.Endpoint

    def simulate(num_of_clients) do
        socket_map = start_a_client(Enum.to_list(1..num_of_clients), %{})
        initalize_data(num_of_clients, socket_map)
        
        Process.sleep(5000)
        sim()
        Process.sleep(15000)
        spawn(fn->fetch_mentions() end)
        Process.sleep(5000)
        spawn(fn->fetch_hash_tags() end)
    end
    
    def initalize_data(num_of_clients, socket_map) do
        :ets.new(:initial_data, [:named_table])
        :ets.insert(:initial_data, {"total_num_of_clients", num_of_clients})
        :ets.insert(:initial_data, {"socket_map", socket_map})
        :ets.insert(:initial_data, {"hash_tags", ["#Zefee","#Pathi","#Pillesh","#Das","#DandhaDas"]})
        :ets.insert(:initial_data, {"sample_tweets", ["Sarlevoi edo friendly ga esam", "Nagaraja Eyy Bus", "Idedo yevvaram la unde","Kurthanam poledinka","Pathyaparalu anni"]})
    end
    
    def start_a_client([client | num_clients], socket_map) do
            {:ok, socket} = connect(TwitterWeb.UserSocket, %{})    
            {:ok, _, socket} = subscribe_and_join(socket, "lobby", %{})
        
            payload = %{username: "user" <> Integer.to_string(client), password: "iggu"}
            push socket, "register_account", payload
            push socket, "login", payload
            socket_map = Map.put(socket_map, "user" <> Integer.to_string(client), socket)
            start_a_client(num_clients, socket_map)
    end
    
    def start_a_client([], socket_map) do
            socket_map
    end

    def sim() do 
        [{_, num_clients}] = :ets.lookup(:initial_data, "total_num_of_clients")
        [{_, socket_map}] = :ets.lookup(:initial_data, "socket_map")
        set_followers(num_clients, socket_map)
        Process.sleep(5000)
        delay = 3000
        for client <- 1..num_clients do
        username = "user" <> Integer.to_string(client)
            spawn(fn -> generate_multiple_tweets(username, Map.get(socket_map,username), delay * client) end)
        end
    end


    def fetch_mentions() do
        [{_, num_clients}] = :ets.lookup(:initial_data, "total_num_of_clients")
        [{_, socket_map}] = :ets.lookup(:initial_data, "socket_map")
        IO.inspect "FETCHING MENTIONS"
    
        client_ids = for _<- 1..5 do
            client = Enum.random(1..num_clients)
        end
    
        for j <- client_ids do
            payload = %{username: "user"<>Integer.to_string(j)}
            socket2 = Map.get(socket_map, "user"<>Integer.to_string(j))
            push socket2, "fetch_mentions", payload

        end
        Process.sleep(5000)
        fetch_mentions()
    end
    
    def fetch_hash_tags() do
        [{_, hash_tags}] = :ets.lookup(:initial_data, "hash_tags")
        [{_, socket_map}] = :ets.lookup(:initial_data, "socket_map")
        IO.inspect "FETCHING HASHTAG TWEETS"
        
        # select 5 random to kill and store these ids in a list
        for i<- 1..5 do
            hashTag = Enum.random(hash_tags)
            payload = %{hashtag: String.trim(hashTag)}
            socket2 = Map.get(socket_map, "user"<>Integer.to_string(i))
            push socket2, "tweetsWithHashtag", payload
        end

        Process.sleep(5000)
        fetch_hash_tags()
    end
    
    def killClients(ip_addr) do
        [{_, num_clients}] = :ets.lookup(:initial_data, "num_of_clientsNodes")
        
        client_ids = for i<- 1..5 do
            client = Enum.random(1..num_clients)
        end
         IO.inspect client_ids
    
        for j <- client_ids do
            spawn(fn -> GenServer.cast(String.to_atom("user"<>Integer.to_string(j)),{:kill_self}) end)
        end
    
        Process.sleep(10000)
    
        IO.inspect "STARTING AGAIN"
        for j <- client_ids do
            spawn(fn -> Client.start_link("user" <> Integer.to_string(j), ip_addr) end)
            spawn(fn -> Client.register_user("user" <> Integer.to_string(j), ip_addr) end)
        end
    end

    def generate_multiple_tweets(username, socket, delay) do
        content = Simulation.get_tweet_content(username)
        payload = %{tweetText: content , username: username}
        push socket, "tweet", payload
        Process.sleep(delay)            
        generate_multiple_tweets(username, socket, delay)
    end
    
    def set_followers(num_clients, socket_map) do
        temp = for j <- 1..num_clients do
            round(1/j)
        end
        c=(100/get_sum(temp,0))
    
        for tweeter <- 1..num_clients, i <- 1..round(Float.floor(c/tweeter)) do
    
                follower = ("user" <> Integer.to_string(Enum.random(1..num_clients)))
                mainUser = ("user" <> Integer.to_string(tweeter))
                push Map.get(socket_map, follower), "subscribeTo", %{username2: mainUser, selfId: follower}
        end
    
        listofFollowersCount = 
        for tweeter <- 1..num_clients do
        {"user" <> Integer.to_string(tweeter) , round(Float.floor(c/tweeter))}
        end
        IO.inspect listofFollowersCount
    end

    def get_sum([first|tail], sum) do
        sum = sum + first
        get_sum(tail,sum)
    end

    def get_sum([], sum) do
        sum
    end
    
    def concatenate([first|tail], string) do
        string = string <> first
        concatenate(tail, string)
    end

    def concatenate([], string) do
        string
    end
    
    
    def get_tweet_content(username) do
        [{_, sample_tweets}] = :ets.lookup(:initial_data, "sample_tweets")
        rand_i = Enum.random(1..Enum.count(sample_tweets))
        chosen_tweet = Enum.at(sample_tweets, rand_i - 1)
        [{_, num_clients}] = :ets.lookup(:initial_data, "total_num_of_clients")
        num_mentions = Enum.random(0..5)
        mentions_list = 
        if num_mentions > 0 do
            for i <- Enum.to_list(1..num_mentions) do
                 "@user" <> Integer.to_string(Enum.random(1..num_clients)) <> " "
            end
        else
            []
        end
        
        [{_, hash_tags}] = :ets.lookup(:initial_data, "hash_tags")
        numTags = Enum.random(0..5)
        hash_tag_list = 
        if numTags > 0 do
            for i <- Enum.to_list(1..numTags) do
                 Enum.at(hash_tags, i - 1)
            end
        else
            []
        end
        chosen_tweet <> concatenate(hash_tag_list, "") <> concatenate(mentions_list, "")
    end
    
    def log(str) do
        IO.puts str
    end
      
end