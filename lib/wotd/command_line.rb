module Wotd
  class CommandLine
    DEFAULT_SUBREDDIT = %w{showerthoughts worldnews todayilearned lifeprotips}

    attr_accessor :options

    def initialize(options)
      @options = options
    end

    def run!
      case
      when options[:show]
        show(options[:show])
      when options[:purge_all]
        purge_all
      when options[:update_only]
        update_only
      when options[:version]
        version
      else
        show
      end
    end

    private

    def purge_all
      DEFAULT_SUBREDDIT.each do |sub|
        wotd = Wotd.new(sub)
        wotd.purge
      end
    end

    def show(subreddit=nil)
      subreddit ||= DEFAULT_SUBREDDIT.sample
      wotd = Wotd.new(subreddit)

      get_method = "get"
      get_method += "!" if not DEFAULT_SUBREDDIT.include?(subreddit)

      puts "r/#{wotd.subreddit}: #{wotd.send(get_method)}"
    end

    def update_only
      DEFAULT_SUBREDDIT.each do |sub|
        wotd = Wotd.new(sub)
        wotd.hit!
      end
    end

    def version
      puts VERSION
    end
  end
end
