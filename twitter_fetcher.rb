require 'sinatra'
require 'sinatra/jsonp'
require 'twitter'

class TwitterFetcher < Sinatra::Base
  helpers Sinatra::Jsonp

  # store development keys in gitignored files
  if Sinatra::Base.development?
    consumer_secret = File.read('.twitter_consumer_secret').strip
    oauth_secret = File.read('.twitter_oauth_secret').strip
  # store production keys in environment variables
  else
    consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
    oauth_secret = ENV['TWITTER_OAUTH_SECRET']
  end

  @@twitter_client = Twitter::Client.new(
    :consumer_key       => 'zHdSQhFBWP3w2MtLYqvejrJcH',
    :consumer_secret    => consumer_secret,
    :oauth_token        => '3048458734-W2JDpijwRaJ8GWAMzWDV4ErPfwSI8hGADgXLgCX',
    :oauth_token_secret => oauth_secret,
  )

  get '/' do
    jsonp @@twitter_client.home_timeline.map(&:attrs)
  end

end
