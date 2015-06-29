require 'redis'
require 'reddit'
require "wotd/version"

module Wotd
  class Wotd
    DAY_IN_SECONDS = 86_4000

    attr_accessor :subreddit

    def initialize(subreddit)
      @subreddit = subreddit
    end

    def update
      top = reddit.articles('top', querystring: 'sort=top&t=day')
      top.each do |article|
        key = "reddit:#{subreddit}:#{article.id}"
        unless redis.exists(key)
          redis.set(key, article.title)
          redis.expire(key, DAY_IN_SECONDS)
        end
      end
    end

    def purge
      redis.keys("reddit:#{subreddit}:*").each do |r|
        redis.del(r)
      end
    end

    def get
      pick = redis.keys("reddit:#{subreddit}:*").sample
      redis.get(pick)
    end

    def get!
      hit!
      get
    end

    def backoff(seconds)
      redis.set("reddit:backoff:#{subreddit}", 1)
      redis.expire("reddit:backoff:#{subreddit}", seconds)
    end

    def hit!
      # update first, before picking
      unless hit?
        update
        backoff(DAY_IN_SECONDS)
      end
    end

    def hit?
      !!redis.get("reddit:backoff:#{subreddit}")
    end

    private

    def reddit
      Reddit::Reddit.new(subreddit)
    end

    def redis
      Redis.new
    end
  end

  def self.update(subreddit)
    Wotd.new(subreddit).update
  end

  def self.get(subreddit)
    Wotd.new(subreddit).get
  end

  def self.hit!(subreddit)
    Wotd.new(subreddit).hit!
  end
end
