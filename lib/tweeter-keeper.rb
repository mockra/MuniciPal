require 'rubygems'
require 'tweetstream'
require 'mongo'
require 'twitter'
require 'date'
require 'time'

#set up a connection to a local MongoDB or MongoLab from Heroku
  if ENV['MONGOLAB_URI']
    uri = URI.parse(ENV['MONGOLAB_URI'])
    conn = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
    db = conn.db(uri.path.gsub(/^\//, ''))
  else
    db = Mongo::Connection.new.db("tweeterkeeper")

  end

#all tweets will be stored in a collection
tweets = db.collection("tweets")

TweetStream.configure do |c|
  c.consumer_key       = 'CCqgXCE1CcsF0xfWXrYN8OESO'
  c.consumer_secret    = '12dLAs7pxrujwpMjTRk9dA1tqJYSDdi7yGSgSh4texHUs8K40h'
  c.oauth_token        = '21616093-upxqHFfYkQ0LBz9MXgBlElegm7qAYD1xOtwF0bUym'
  c.oauth_token_secret = 'x7qZPW1dMeBDRubhfCXMo5Re5SIDtmZd9WAa9b9c0Vkx4'
  c.auth_method = :oauth
end

client = TweetStream::Client.new()

a = []
client.locations(-111.894881,33.277385,-111.580636,33.513323) do |status|
  tweets.insert(status.to_h)
  tweets.ensure_index([[status.to_h.coordinates, Mongo::GEO2D]])
end
