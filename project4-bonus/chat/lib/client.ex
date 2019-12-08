defmodule Client do
    use GenServer
    require Logger

    def start_link(userId,noOfTweets,noToSubscribe, noOfClients, existingUser) do
        GenServer.start_link(__MODULE__, [userId,noOfTweets,noToSubscribe, noOfClients, existingUser])
    end

    def init([userId,noOfTweets,noToSubscribe, noOfClients, existingUser]) do
        #Register Account
        if existingUser do
            IO.puts "User #{userId} :- reconnected"
            login_handler(userId)
        end
        :global.sync()
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:userRegistration,userId,self()})
        {:ok, {userId, noOfTweets, 0, noToSubscribe, noOfClients, 0, 0, 0, 0, 0}}
    end

    def handle_cast({:registerConfirmation}, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}) do
        IO.puts "User #{userId} :- has joined the Twitter Server!"

        ChatWeb.RoomChannel.registrationConfirmation(userId)

        {:noreply, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}}
    end

    def login_handler(userId) do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:loginUser,userId,self()})
        for _ <- 1..5 do
            GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:tweetParse,"Tweet by user#{userId} : FSU sucks",userId})
        end
    end

    def client_handler(userId,noOfTweets,noToSubscribe, noOfClients) do
        #Mention
        userToMention = Enum.random(List.delete(Enum.to_list(1..noOfClients), String.to_integer(userId)))
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:tweetParse,"user#{userId} tweeting @#{userToMention}",userId})

        #Hashtag
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:tweetParse,"user#{userId} tweeting that #BEATFSU",userId})

        #GenServer.cast Tweets
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:tweetParse,"Tweet by user#{userId} : FSU sucks",userId})

        #ReTweet
        handle_retweet(userId)
        #Live View
    end

    def handle_subscribe(userId,subscribeToList) do
        Enum.each subscribeToList, fn accountId ->
            GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:addToSubscriberList,userId,Integer.to_string(accountId)})
        end
    end

    def handle_retweet(userId) do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:subscribedTweets,userId})
    end

    def handle_cast({:clientSubscribedTweets,list}, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}) do
        if(tweetsDone+3 <= noOfTweets) do
            if(list != []) do
                rt = hd(list)
                GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:tweetParse,rt <> " -RT",userId})
            end
            #Queries
            start_time = System.system_time(:millisecond)
            handle_queries_subscribedto(userId)
        end
        {:noreply, {userId, noOfTweets, tweetsDone+1, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}}
    end

    def handle_cast({:live,tweetString}, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}) do
        IO.inspect tweetString, label:  "User #{userId} :- Real Time Tweets ->->"
        {:noreply, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}}
    end

    def handle_get_my_tweets(userId) do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:queryOwnTweets,userId})
    end

    def handle_cast({:clientQueryOwnTweets,list}, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}) do
        IO.inspect list, label: "User #{userId} :- All my tweets"

        queries_myTweets_time_diff = System.system_time(:millisecond) - start_time

        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:perfmetrics,tweets_time_diff,queries_subscribedto_time_diff,queries_hashtag_time_diff,queries_mention_time_diff,queries_myTweets_time_diff})

        {:noreply, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}}
    end

    def handle_queries_subscribedto(userId) do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:subscribedTweets2,userId})
    end

    def handle_cast({:clientSubscribedTweets2,list}, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}) do
        tweets_time_diff = System.system_time(:millisecond) - tweets_time_diff
        tweets_time_diff = tweets_time_diff/(noOfTweets)
        if list != [], do: IO.inspect list, label: "User #{userId} :- Tweets Subscribed To"
        queries_subscribedto_time_diff = System.system_time(:millisecond) - start_time

        start_time = System.system_time(:millisecond)
        handle_queries_hashtag("#BEATFSU",userId)
        {:noreply, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}}
    end

    def handle_queries_hashtag(tag,userId) do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:hashTweets,tag,userId})
    end

    def handle_cast({:clientHashTweets,tag,list}, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}) do
        IO.inspect list, label: "User #{userId} :- Tweets With #{tag}"
        queries_hashtag_time_diff = System.system_time(:millisecond) - start_time

        start_time = System.system_time(:millisecond)
        handle_queries_mention(userId)
        {:noreply, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}}
    end

    def handle_queries_mention(userId) do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:mentionTweets,userId})
    end

    def handle_cast({:clientMentionTweets,list}, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}) do
        IO.inspect list, label: "User #{userId} :- Tweets With @#{userId}"
        queries_mention_time_diff = System.system_time(:millisecond) - start_time

        start_time = System.system_time(:millisecond)
        #Get All Tweets
        handle_get_my_tweets(userId)
        {:noreply, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}}
    end

    def randomizer(l) do
      :crypto.strong_rand_bytes(l) |> Base.url_encode64 |> binary_part(0, l) |> String.downcase
    end

    def handle_cast({:userDeletion}, state) do
        terminate()
        {:noreply, state}
    end

    def terminate() do
        send(self(), :terminate)
    end



    #-----------------------------------------------------------------------------------------------------------
    def register() do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:userRegistration,@userId,self()})
    end

    def login() do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:loginUser,@userId,self()})
    end

    def subscribeToUser(accountId) do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:addToSubscriberList,@userId,Integer.to_string(accountId)})
    end

    def tweet(message) do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:tweetParse, message, @userId})
    end

    def retweet(message) do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")), {:tweetParse, message <> " -RT", @userId})
    end

    def get_my_tweets() do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")), {:queryOwnTweets, @userId})
    end

    def send_perf_metrics(tweets_time_diff,queries_subscribedto_time_diff,queries_hashtag_time_diff,queries_mention_time_diff,queries_myTweets_time_diff) do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")),{:perfmetrics})
    end

    def query_hashtag(tag) do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")), {:hashTweets, tag})
    end

    def query_mentions() do
        GenServer.cast(:global.whereis_name(String.to_atom("Server")), {:mentionTweets, @userId})
    end
end
