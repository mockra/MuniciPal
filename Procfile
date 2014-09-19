web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: bundle exec ruby lib/tweeter-keeper.rb
mosqltask: mosql -c config/tweets.yaml --sql $DATABASE_URL --mongo $MONGOLAB_URI
