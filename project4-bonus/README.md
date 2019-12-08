- Team members

Satya Abhiram Theli : UFID 5958-3952
Sahil Bhalla : UFID 1699-2193

- What is working

- Clients 
Clients are being spawned using GenServer. They connect and register as Users. Server handles connections and disconnections of clients. Clients also do live tweets, and a small sub group as re-tweets.

They also print metrics. They query the server for tweets subscribed to,  by the client in question, and displays these tweets as well. Similary they query for the clients hashtags and mentions. They also query for their own tweets. 

- Server
The server contains the handle casts for all functionalities. These include :
a) User Registration
b) User Deletion
c) User Dropped
d) Querying User Tweets
e) Getting List of Subscribers
f) Getting List of followers
g) Adding to List of Subscribers
h) Adding to List of Followers
i) Parsing of Tweets
j) Parsing of Hashtags (#)
k) Parsing of mentions (@)

- Main Function
Spawns Server, as well as the clients. It also simulates the connections as well as disconnections.

At the end, the client prints its own performance statistics. 
The Test Cases also run and can be run using 'mix test'

- Mention all the test cases that you created

Using the ExUnit framework, we have implemented the following Test Cases :
1) User Table Creation Test
2) User Insertion Test
3) Querying Server for User Tweets Test
4) Add to Subscriber List Test
5) Mentions Parsing Test
6) Hashtags Parsing Test
7) User Registration Test

