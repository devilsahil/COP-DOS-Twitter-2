defmodule Client do
    use GenServer
    require Logger

    def start_link(userId, noOfTweets, noToSubscribe, noOfClients, existingUser) do
        GenServer.start_link(__MODULE__, [userId, noOfTweets, noToSubscribe, noOfClients, existingUser])
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

#-----------------------------------------------------------------------------------------------------------

    def init([userId,noOfTweets,noToSubscribe, noOfClients, existingUser]) do
        :global.sync()
        {:ok, {userId, noOfTweets, 0, noToSubscribe, noOfClients, 0, 0, 0, 0, 0}}
    end

    def handle_cast({:registerConfirmation, userId}, state) do
        IO.puts "User #{userId} :- has joined the Twitter Server!"
        ChatWeb.RoomChannel.registrationConfirmation(userId)

        {:noreply, state}
    end

    def handle_cast({:clientSubscribedTweets, list}, state) do
        ChatWeb.RoomChannel.subscribedTweets(list)
        {:noreply, state}
    end

    def handle_cast({:live,tweetString}, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}) do
        IO.inspect tweetString, label:  "User #{userId} :- Real Time Tweets ->->"
        ChatWeb.RoomChannel.liveTweets(tweetString)
        {:noreply, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}}
    end

    def handle_cast({:clientQueryOwnTweets,list}, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}) do
        ChatWeb.RoomChannel.ownTweets(list)
        {:noreply, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}}
    end

    def handle_cast({:clientHashTweets,tag,list}, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}) do
        ChatWeb.RoomChannel.hashTweets(list)
        {:noreply, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}}
    end

    def handle_cast({:clientMentionTweets,list}, {userId, noOfTweets, tweetsDone, noToSubscribe, noOfClients, start_time, tweets_time_diff, queries_subscribedto_time_diff, queries_hashtag_time_diff, queries_mention_time_diff}) do
        ChatWeb.RoomChannel.mentionTweets(list)
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

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
end
