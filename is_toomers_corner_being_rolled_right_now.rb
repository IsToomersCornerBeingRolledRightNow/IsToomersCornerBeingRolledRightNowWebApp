require 'sinatra'
require "sinatra/json"
require 'twitter'
require 'erb'
require 'json'

# monkey-patch time methods on integer ala active support
class Integer
  def seconds
    self
  end
  def minutes
    seconds*60
  end
  def hours
    minutes*60
  end
end

# store development keys in gitignored files
if Sinatra::Base.development?
  CONSUMER_SECRET = File.read('.twitter_consumer_secret').strip
  OAUTH_SECRET = File.read('.twitter_oauth_secret').strip
# store production keys in environment variables
else
  CONSUMER_SECRET = ENV['TWITTER_CONSUMER_SECRET']
  OAUTH_SECRET = ENV['TWITTER_OAUTH_SECRET']
end

# wire up Twitter using keys and secrets
TWITTER_CLIENT = Twitter::Client.new(
  :consumer_key       => 'zHdSQhFBWP3w2MtLYqvejrJcH',
  :consumer_secret    => CONSUMER_SECRET,
  :oauth_token        => '3048458734-W2JDpijwRaJ8GWAMzWDV4ErPfwSI8hGADgXLgCX',
  :oauth_token_secret => OAUTH_SECRET,
)

# custom class to handle tweets, including serialization for persistence
class ToomersTweet
  def initialize hash=nil
    if hash
      @hash = hash
      @cached = false
    else
      if File.exist?('.twitter_cache')
        @hash = JSON.parse File.read('.twitter_cache'), symbolize_names: true
        @cached = true
      end
      if !@hash || needs_refresh?
        twitter_tweets = TWITTER_CLIENT.home_timeline(count:1)
        twitter_tweet = twitter_tweets.first
        @hash = {
          id:         twitter_tweet.attrs[:id],
          created_at: twitter_tweet.attrs[:created_at],
          text:       twitter_tweet.attrs[:text],
          html:       TWITTER_CLIENT.oembed(twitter_tweet.attrs[:id], align: :center).html,
          cached_on:  Time.now.to_s
        }
        @cached = false
        f = File.open('.twitter_cache', 'w')
        f.puts(to_json)
        f.close
      end
    end
  end
  def created_at
    Time.parse @hash[:created_at]
  end
  def id
    @hash[:id]
  end
  def html
    @hash[:html]
  end
  def text
    @hash[:text]
  end
  def cached_on
    Time.parse @hash[:cached_on]
  end
  def response
    text.match(%r{[a-zA-Z0-9\-\_]*}).to_s
  end
  def needs_refresh?
    !cached_on || cached_on < Time.now - 75.seconds
  end
  def is_stale?
    created_at < Time.now - 2.hours
  end
  def status
    if is_stale?
      'No.'
    else
      response
    end
  end
  def to_json
    JSON.dump @hash
  end
  def to_hash
    @hash
  end
end


class IsToomersCornerBeingRolledRightNow < Sinatra::Base
  helpers Sinatra::JSON

  def tweet
    unless @tweet
      @tweet = ToomersTweet.new
    end
    @tweet
  end

  get("/api"){redirect to('/api/')}
  get "/api/" do
    json tweet.to_hash
  end

  get '/' do
    ERB.new(File.read 'view.html.erb').result(binding)
  end

end
