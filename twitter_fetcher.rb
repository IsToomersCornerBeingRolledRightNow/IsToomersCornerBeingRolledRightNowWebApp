require 'sinatra'
require "sinatra/json"
require 'twitter'

class IsToomersCornerBeingRolledRightNow < Sinatra::Base
  helpers Sinatra::JSON

  # store development keys in gitignored files
  if Sinatra::Base.development?
    consumer_secret = File.read('.twitter_consumer_secret').strip
    oauth_secret = File.read('.twitter_oauth_secret').strip
  # store production keys in environment variables
  else
    consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
    oauth_secret = ENV['TWITTER_OAUTH_SECRET']
  end

  # wire up Twitter using keys and secrets
  @@twitter_client = Twitter::Client.new(
    :consumer_key       => 'zHdSQhFBWP3w2MtLYqvejrJcH',
    :consumer_secret    => consumer_secret,
    :oauth_token        => '3048458734-W2JDpijwRaJ8GWAMzWDV4ErPfwSI8hGADgXLgCX',
    :oauth_token_secret => oauth_secret,
  )

  def latest_tweet
    unless @latest_tweet
      latest_tweets = @@twitter_client.home_timeline(count:1)
      @latest_tweet = latest_tweets.first
    end
    @latest_tweet
  end

  def latest_tweet_oembed
    @latest_tweet_oembed || @latest_tweet_oembed = @@twitter_client.oembed(latest_tweet.attrs[:id])
  end

  def latest_tweet_html
    latest_tweet_oembed.html
  end

  def latest_tweet_response
    latest_tweet.attrs[:text].split(' ').first[0...-1].downcase
  end

  def latest_tweet_id
    latest_tweet.attrs[:id]
  end

  get '/api/' do
    json response: latest_tweet_response,
         id:       latest_tweet_id,
         html:     latest_tweet_html
  end

  get '/' do
    'foo'
  end

end
