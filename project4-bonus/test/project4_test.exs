# File: assertion_test.exs

# 1) Start ExUnit.
ExUnit.start()

# 2) Create a new test module (test case) and use "ExUnit.Case".
defmodule AssertionTest do
  # 3) Notice we pass "async: true", this runs the test case
  #    concurrently with other test cases. The individual tests
  #    within each test case are still run serially.
  use ExUnit.Case, async: true

  # 4) Use the "test" macro instead of "def" for clarity.
  test "the truth" do
    if 1==1 do
      assert true
    else
      assert false
    end
  end

  test "User Table Creation Test" do
    :ets.new(:userTable, [:set, :public, :named_table])
    assert :ets.info(:userTable) do :undefined end
  end

  test "User Insertion Test" do
    :ets.new(:userTable, [:set, :public, :named_table])
    :ets.insert_new(:userTable, {"@sahil", self()})
    assert :ets.member(:userTable, "@sahil") do true end
  end

  test "Server Query User Tweets Test" do
    :ets.new(:tweetTable, [:set, :public, :named_table])
    :ets.insert(:tweetTable, {1011, ["hi"]})
    assert Server.queryUserTweetsTestFn(1011) do true end

  end

  test "Server Add to Subscriber List Test" do
    :ets.new(:subscribedtoTable, [:set, :public, :named_table])
    :ets.insert(:subscribedtoTable, {1011, [1,2,3]})
    assert Server.addToSubscriberListTestFn(1011,5) do true end

  end

  test "Mentions Test" do
    :ets.new(:mentionsTable, [:set, :public, :named_table])
    :ets.insert(:mentionsTable, {"@1011", ["Hi @1011"]})
    assert Server.mentionTweetsTestFn("1011") do true end

  end

  test "Hashtags Test" do
    :ets.new(:hashtagTable, [:set, :public, :named_table])
    :ets.insert(:hashtagTable, {"#abhiram", ["Hi #abhiram"]})
    assert Server.hashTweetsTestFn("#abhiram") do true end

  end
#ReTweets Test Not Working####################################
  test "ReTweets Test" do
    :ets.new(:subscribedtoTable, [:set, :public, :named_table])
    :ets.insert(:subscribedtoTable, {1011, [1,2,3]})
    assert Server.reTweetsTestFn(1011) do true end

  end

  test "User Registration Test" do
    :ets.new(:userTable, [:set, :public, :named_table])
    :ets.new(:tweetTable, [:set, :public, :named_table])
    :ets.new(:subscribedToTable, [:set, :public, :named_table])
    :ets.new(:followerTable, [:set, :public, :named_table])

   Server.userRegistrationTestFn(1011, 123)
   assert :ets.lookup(:userTable, {1011}) do true end


  end
#Tweet Parsing Test Not Working###########################
  test "Tweet Parsing Test" do
    :ets.new(:userTable, [:set, :public, :named_table])
    :ets.new(:tweetTable, [:set, :public, :named_table])
    :ets.new(:subscribedToTable, [:set, :public, :named_table])
    :ets.new(:followerTable, [:set, :public, :named_table])

   Server.tweetParseTestFn("Hello tweet", 1011)
   assert :ets.lookup(:userTable, {1011}) do true end


  end

end
