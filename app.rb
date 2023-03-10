require "rss"
require "net/http"
require "uri"
require 'dotenv/load'

# Config
$access_token = ENV["ACCESS_TOKEN"]
$start_time = Time.now
interval = 300
spiegel_rss = "https://www.spiegel.de/schlagzeilen/index.rss"

puts "[APP] Initializing"
puts "\n"

# Fetching and parsing feed
def read_feed(url, interval)
    response = Net::HTTP.get_response(URI(url))
    if response.is_a?(Net::HTTPSuccess)
        feed = RSS::Parser.parse(response.body, false)
        puts "[SPIEGEL RSS] Fetching feed"
        puts "\n"
        feed.items.each do |item|
            date = item.pubDate.to_time
            time_difference = Time.now - interval
            # Make sure no duplicates are posted when restarting the app
            time_difference = $start_time if time_difference < $start_time
            if date >= time_difference
                puts "[SPIEGEL RSS] New article: #{item.title}"
                # Substitute title for description in case none is provided
                item.description.empty? ? description = item.title : description = item.description
                description = description.slice(0, 140) + "..." if description.length > 140
                puts "[MASTODON] Posting article"
                post(description, item.link)
                puts "\n"
            end
        end
    else
        puts "[SPIEGEL RSS] Error " + response.code
        puts "\n"
    end
    sleep(interval)
    read_feed(url, interval)
end

# Posting article
def post(description, link)
    uri = URI("https://mstdn.social/api/v1/statuses")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{$access_token}"
    req.set_form(
        [
            [
            "status",
            "#{description} #{link}"
            ]
        ],
        "multipart/form-data"
    )
    req_options = {
        use_ssl: uri.scheme == "https"
    }
    res = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(req)
    end
    puts "[MASTODON] Status: #{res.code} #{res.message}"
end

# Start app
read_feed(spiegel_rss, interval)