require 'redis'
require 'reddit'
require "wotd/version"

module Wotd
  class Wotd
    DAY_IN_SECONDS = 86_4000
    MONTH_IN_SECONDS = 2_688_000

    attr_accessor :subreddit

    def initialize(subreddit)
      @subreddit = subreddit
    end

    def update
      top = reddit.top
      top.each do |article|
        key = "reddit:#{subreddit}:#{article.id}"
        unless redis.exists(key)
          redis.set(key, article.title)
          redis.expire(key, MONTH_IN_SECONDS)
        end
      end
    end

    def purge
      redis.keys("reddit:#{subreddit}:*").each do |r|
        redis.del(r)
      end
    end

    def get
      # update first, before picking
      update unless backoff?
      backoff(DAY_IN_SECONDS)

      pick = redis.keys("reddit:#{subreddit}:*").sample
      redis.get(pick)
    end

    def backoff(seconds)
      redis.set("wotd:#{subreddit}", 1)
      redis.expire("wotd:#{subreddit}", seconds)
    end

    def backoff?
      !!redis.get("wotd:#{subreddit}")
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
end
