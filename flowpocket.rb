require "redis"
require "twitter-text"
require "faraday"
require "faraday_middleware"
require "faraday/detailed_logger"
require "cgi"
include Twitter::Extractor

POCKET_API_URL = ENV.fetch("POCKET_API_URL", "https://getpocket.com/v3/")
FLOWDOCK_API_URL = ENV.fetch("FLOWDOCK_API_URL", "https://api.flowdock.com")
TAG = ENV.fetch("FLOWDOCK_TAG", "goodread")
REDIS_KEY = ENV.fetch("REDIS_KEY", "flowpocket")
LOGGER = Logger.new(STDOUT)

REDIS = Redis.new

FLOWDOCK_CONNECTION = Faraday.new(FLOWDOCK_API_URL) do |faraday|
  faraday.use Faraday::Response::RaiseError
  faraday.basic_auth ENV["FLOWDOCK_API_TOKEN"], ""
  faraday.request :json
  faraday.response :json, content_type: /\bjson$/
  faraday.adapter Faraday.default_adapter
end

POCKET_CONNECTION = Faraday.new(POCKET_API_URL) do |faraday|
  faraday.use Faraday::Response::RaiseError
  faraday.request :json
  faraday.response :json, content_type: /\bjson$/
  faraday.response :detailed_logger
  faraday.adapter Faraday.default_adapter
end

def fetch_messages(flow)
  url = flow["url"] + "/messages?event=message&tags=#{CGI.escape(TAG)}"
  FLOWDOCK_CONNECTION.get(url).body
end

def mark_as_synced(url)
  REDIS.sadd(REDIS_KEY, url)
end

def synced?(url)
  REDIS.sismember(REDIS_KEY, url)
end

def post_url_to_pocket(url, tags)
  base = {
    access_token: ENV["POCKET_ACCESS_TOKEN"],
    consumer_key: ENV["POCKET_CONSUMER_KEY"]
  }

  POCKET_CONNECTION.post("add", base.merge(url: url, tags: tags)).body["item"]
end

def url?(url)
  url.start_with?("https://") || url.start_with?("http://")
end

def post_url(url, tags = [])
  begin
    post_url_to_pocket(url, tags)
    mark_as_synced(url)
  rescue => exception
    LOGGER.info("Failed to post #{url}: #{exception.inspect}")
  end
end

organization_access_flows = FLOWDOCK_CONNECTION.get("/flows").body.select do |flow|
  flow["access_mode"] == "organization"
end

organization_access_flows.each do |flow|
  fetch_messages(flow).each do |message|
    extract_urls(message["content"]).each do |url|
      post_url(url, []) if !synced?(url) && url?(url)
    end
  end
end
