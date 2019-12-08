defmodule Server do
  use GenServer

  def start_link(totalClients) do
    GenServer.start_link(__MODULE__, [totalClients], name: {:global, String.to_atom("Server")})
  end

  def whereis(uid) do
    if uid == [] do
        nil
    end
    if :ets.lookup(:userTable, uid) == [] do
        nil
    else
        [tup] = :ets.lookup(:userTable, uid)
        elem(tup, 1)
    end
end

  def userRegistration(pid, currentNode, node, uid) do
    GenServer.cast(pid, {:userRegistration, uid, pid})
  end

  def handle_cast({:userRegistration, uid, pid}, state) do
    :ets.insert(:userTable, {uid, pid})
    :ets.insert(:tweetTable, {uid, []})
    :ets.insert(:subscribedtoTable, {uid, []})
    if :ets.lookup(:followerTable, uid) == [], do: :ets.insert(:followerTable, {uid, []})
    GenServer.cast(pid,{:registerConfirmation})
    {:noreply, state}
  end

def userDropped(uid, pid) do
  GenServer.cast(pid, {:userDropped, uid, pid})
end

def handle_cast({:userDropped, uid}, state) do
  :ets.insert(:userTable, {uid, nil})
  {:noreply, state}
end


def handle_cast({:userDeletion, uid}, state) do
  :ets.delete(:userTable, uid)
  {:noreply, state}
end

def queryUserTweets(uid) do
  if :ets.lookup(:tweetTable, uid) == [] do
    []
  else
    [tup] = :ets.lookup(:tweetTable, uid)
    elem(tup, 1)
  end

end

def handle_cast({:queryOwnTweets, uid}, state) do
  [tup] = :ets.lookup(:tweetTable, uid)
  list = elem(tup, 1)
  GenServer.cast(whereis(uid),{:clientQueryOwnTweets,list})
  {:noreply, state}
end

def getSubscriberList(uid) do
  [tup] = :ets.lookup(:subscribedtoTable, uid)
  elem(tup, 1)

end

def handle_cast({:getFollowerList, uid}, state) do
  [tup] = :ets.lookup(:followerTable, uid)
  elem(tup, 1)
  {:noreply, state}
end

def handle_cast({:addToSubscriberList, uid, sub}, state) do
  [tup] = :ets.lookup(:subscribedtoTable, uid)
  list = elem(tup, 1)
  list = [sub | list]
  :ets.insert(:subscribedtoTable, {uid, list})

  if :ets.lookup(:followerTable, sub) == [], do: :ets.insert(:followerTable, {sub, []})
  [tup] = :ets.lookup(:followerTable, sub)
  list = elem(tup, 1)
  list = [uid | list]
  :ets.insert(:followerTable, {sub, list})
  {:noreply, state}
end


#----------------BREAK INTO 2---------------------#



def handle_cast({:tweetParse,tweet ,uid}, state) do
  [tup] = :ets.lookup(:tweetTable, uid)
  list = elem(tup,1)
  list = [tweet | list]
  :ets.insert(:tweetTable,{uid,list})

  hashtagsList = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweet) |> Enum.concat
  Enum.each hashtagsList, fn hashtag ->
    hashtagParser(hashtag,tweet)
  end
  mentionsList = Regex.scan(~r/\B@[a-zA-Z0-9_]+/, tweet) |> Enum.concat
  Enum.each mentionsList, fn mention ->
    mentionParser(mention,tweet)
      userName = String.slice(mention,1, String.length(mention)-1)
      if whereis(userName) != nil, do: GenServer.cast(whereis(userName),{:live,tweet})
  end

  [{_,followersList}] = :ets.lookup(:followerTable, uid)
  Enum.each followersList, fn follower ->
    if whereis(follower) != nil, do: GenServer.cast(whereis(follower),{:live,tweet})
  end
  {:noreply, state}
end


#----------------------------------------------------------

def hashtagParser(tag, tweet) do
  [tup] = if :ets.lookup(:hashtagTable, tag) != [] do
    :ets.lookup(:hashtagTable, tag)
else
    [nil]
end
if tup == nil do
    :ets.insert(:hashtagTable,{tag,[tweet]})
else
    list = elem(tup,1)
    list = [tweet | list]
    :ets.insert(:hashtagTable,{tag,list})
end

end

#----------------------------------------------------------

def mentionParser(tag, tweet) do
  [tup] = if :ets.lookup(:mentionsTable, tag) != [] do
    :ets.lookup(:mentionsTable, tag)
else
    [nil]
end
if tup == nil do
    :ets.insert(:mentionsTable,{tag,[tweet]})
else
    list = elem(tup,1)
    list = [tweet | list]
    :ets.insert(:mentionsTable,{tag,list})
end
end


#----------------BREAK INTO 2---------------------#



def handle_cast({:subscribedTweets, uid}, state) do
  subscribedTo = getSubscriberList(uid)
  list = tweetGen(subscribedTo,[])
  GenServer.cast(whereis(uid),{:clientSubscribedTweets,list})
  {:noreply, state}
end

def handle_cast({:subscribedTweets2, uid}, state) do
  subscribedTo = getSubscriberList(uid)
  list = tweetGen(subscribedTo,[])
  GenServer.cast(whereis(uid),{:clientSubscribedTweets2,list})
  {:noreply, state}
end

def handle_cast({:reTweets, uid}, state) do
  subscribedTo = getSubscriberList(uid)
  list = tweetGen(subscribedTo,[])
  GenServer.cast(whereis(uid),{:clientReTweets,list})
  {:noreply, state}
end


#def handle_cast({:tweetsGen, [head | tail],tweetlist}, state) do
#  subscribedTo = get_subscribed_to(uid)
#  list = generate_tweet_list(subscribedTo,[])
#  GenServer.cast(whereis(uid),{:clientSubscribedTweets,list})
#  {:noreply, state}
#end

#def handle_cast({:emptyTweetsGen, [],tweetlist}, state) do
#  tweetlist
#  {:noreply, state}
#end

def tweetGen([head | tail],tweetlist) do
  tweetlist = queryUserTweets(head) ++ tweetlist
  tweetGen(tail,tweetlist)
end

def tweetGen([],tweetlist), do: tweetlist

#--------------------------------------------------------

def handle_cast({:hashTweets,hashTag, uid}, state) do
  [tup] = if :ets.lookup(:hashtagTable, hashTag) != [] do
    :ets.lookup(:hashtagTable, hashTag)
else
    [{"#",[]}]
end
list = elem(tup, 1)
GenServer.cast(whereis(uid),{:clientHashTweets, hashTag,list})
  {:noreply, state}
end
#--------------------------------------------------------

def handle_cast({:mentionTweets, uid}, state) do
  [tup] = if :ets.lookup(:mentionsTable, "@" <> uid) != [] do
    :ets.lookup(:mentionsTable, "@" <> uid)
else
    [{"#",[]}]
end
list = elem(tup, 1)
GenServer.cast(whereis(uid),{:clientMentionTweets,list})
  {:noreply, state}
end


  def init([totalClients]) do
    #idk what the next line does so commented --REMOVE
    # {:ok,iflist}=:inet.getif()
    :ets.new(:userTable, [:set, :public, :named_table])
    :ets.new(:tweetTable, [:set, :public, :named_table])
    :ets.new(:hashtagTable, [:set, :public, :named_table])
    :ets.new(:mentionsTable, [:set, :public, :named_table])
    :ets.new(:subscribedtoTable, [:set, :public, :named_table])
    :ets.new(:followerTable, [:set, :public, :named_table])
    #Not sure how we're supposed to spawn the api handler process --REMOVE
    #server_id = spawn_link(fn() -> api_handler() end)
    #:global.register_name(:TwitterServer,server_id)
    IO.puts "Server Started"
    {:ok, {0,totalClients,0,0,0,0,0}}
end

#-----------------------------------------------------------------------------------------------------------------------

def handle_cast({:loginUser,userId,pid}, state) do
  :ets.insert(:userTable, {userId, pid})
  {:noreply, state}
end

#-----------------------------------------------------------------------------------------------------------------------

  def print_performance_metrics(totalClients,tweets_time_diff,queries_subscribedto_time_diff,queries_hashtag_time_diff,queries_mention_time_diff,queries_myTweets_time_diff) do
      IO.puts "Avg. time to tweet: #{tweets_time_diff/totalClients} milliseconds"
      IO.puts "Avg. time to query tweets subscribe to: #{queries_subscribedto_time_diff/totalClients} milliseconds"
      IO.puts "Avg. time to query tweets by hashtag: #{queries_hashtag_time_diff/totalClients} milliseconds"
      IO.puts "Avg. time to query tweets by mention: #{queries_mention_time_diff/totalClients} milliseconds"
      IO.puts "Avg. time to query all relevant tweets: #{queries_myTweets_time_diff/totalClients} milliseconds"
  end


  def handle_cast({:perfmetrics, a, b, c, d, e}, {numClients,totalClients,tweets_time_diff,queries_subscribedto_time_diff,queries_hashtag_time_diff,queries_mention_time_diff,queries_myTweets_time_diff}) do
    if(numClients+1 == totalClients) do
      numClients = 0
      print_performance_metrics(totalClients,tweets_time_diff+a,queries_subscribedto_time_diff+b,queries_hashtag_time_diff+c,queries_mention_time_diff+d,queries_myTweets_time_diff+e)
    end
    {:noreply, {numClients+1,totalClients,tweets_time_diff+a,queries_subscribedto_time_diff+b,queries_hashtag_time_diff+c,queries_mention_time_diff+d,queries_myTweets_time_diff+e}}
  end

#----------------------TEST FUNCTIONS-----------------------------------------------------------------------------------
def queryUserTweetsTestFn(uid) do
  if :ets.lookup(:tweetTable, uid) == [] do
    IO.inspect([])
  else
    [tup] = :ets.lookup(:tweetTable, uid)
    IO.inspect(elem(tup, 1))
  end

end

def addToSubscriberListTestFn(uid, sub) do
  [tup] = :ets.lookup(:subscribedtoTable, uid)
  list = elem(tup, 1)
  list = [sub | list]
  IO.inspect(list)
  :ets.insert(:subscribedtoTable, {uid, list})

end

def mentionTweetsTestFn(uid) do
  [tup] = if :ets.lookup(:mentionsTable, "@" <> uid) != [] do
    :ets.lookup(:mentionsTable, "@" <> uid)
else
    [{"#",[]}]
end
list = elem(tup, 1)
IO.inspect(list)
end

def hashTweetsTestFn(hashTag) do
  [tup] = if :ets.lookup(:hashtagTable, hashTag) != [] do
    :ets.lookup(:hashtagTable, hashTag)
else
    [{"#",[]}]
end
list = elem(tup, 1)
IO.inspect(list)
end

def userRegistrationTestFn(uid, pid) do
  :ets.insert(:userTable, {uid, pid})
  :ets.insert(:tweetTable, {uid, []})
  IO.inspect(:ets.lookup(:userTable, {1011}))
  #:ets.insert(:subscribedtoTable, {uid, []})
  #if :ets.lookup(:followerTable, uid) == [], do: :ets.insert(:followers, {uid, []})

end

def tweetParseTestFn(tweet ,uid) do
  [tup] = :ets.lookup(:tweetTable, uid)
  list = elem(tup,1)
  list = [tweet | list]
  :ets.insert(:tweetTable,{uid,list})

end

def reTweetsTestFn(uid) do
  subscribedTo = getSubscriberList(uid)
  list = tweetGen(subscribedTo,[])
  IO.inspect(list)
end


end
