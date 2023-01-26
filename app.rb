require "rss"
require "net/http"
require "uri"
require "open-uri"

# config

$access_token = ENV["ACCESS_TOKEN"]
interval = 300
spiegel_rss = "https://www.spiegel.de/schlagzeilen/index.rss"

# fetching and parsing feed

def read_feed(url, interval)
    URI.open(url) do |rss|
        feed = RSS::Parser.parse(rss, false)
        puts "[SPIEGEL RSS] Fetching feed"
        puts "\n"
        feed.items.each do |item|
            date = item.pubDate.to_time
            if date >= Time.now - interval
                puts ""
                puts "[SPIEGEL RSS] New article: #{item.title}"
                description = item.description.slice(0, 140) + "..." if item.description.length > 140
                puts "[MASTODON] Posting article"
                post(description, item.link)
                puts "\n"
            end
        end
    end
    sleep(interval)
    read_feed(url, interval)
end

# posting article

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

# start process

read_feed(spiegel_rss, interval)