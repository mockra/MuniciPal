web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: bundle exec ruby lib/tweeter-keeper.rb
worker: mosql -c config/tweets.yaml --sql ENV['DATABASE_URL'] --mongo ENV['MONGOLAB_URI']
