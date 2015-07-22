require 'rubygems'
require 'hpricot'
require 'net/http'
require 'parallel'
require 'yaml'

class Redback

  def initialize(url, &each_site)
    url = fix_url_formatting(url)

    @http_headers = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'http_headers.yml'))['headers']

    @pages_hit = 0

    @visited = []
    @to_visit = []

    @each_site = each_site

    @options = {
      :ignore_hash => true,
      :ignore_query_string => false,
      :search_in_comments => false,
      :threads => 4,
      :num_pages => 1000
    }

    crawl_page(url)
    spider
  end

  def fix_url_formatting(url)
    url = url.strip
    url = "http://#{url}" unless url[/^http:\/\//] || url[/^https:\/\//]
    url = "#{url}/" unless url.strip[-1] == "/"
    url
  end

  def queue_link(url)
    @to_visit << url
  end

  def crawl_page(url, limit = 10)
    # Don't crawl a page twice
    return if @visited.include? url

    # Let's not hit this again
    @visited << url

    begin
      uri = URI.parse(URI.encode(url.to_s.strip))
    rescue => er
      puts "Could not parse URL: #{url}"
      puts er.message
      puts er.backtrace.join("\n")
      return
    end

    begin
      req = Net::HTTP::Get.new(uri.path, @http_headers)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }

      case response
        when Net::HTTPRedirection
          return crawl_page(response['location'], limit - 1)
        when Net::HTTPSuccess
          doc = Hpricot(response.body)
          @each_site.call url
      end
    rescue => er
      puts 'Could not get website content'
      puts er.message
      puts er.backtrace.join("\n")
      return
    end

    @pages_hit += 1

    find_links(doc, url) do |link|
      next if @visited.include? link
      next if @to_visit.include? link

      @to_visit << link
    end
  end

  def find_links(doc, url)
    return unless doc.respond_to? 'search'

    begin
      uri = URI.parse(URI.encode(url.to_s.strip))
    rescue => er
      puts "Could not parse url: #{url}"
      puts er.message
      puts er.backtrace.join("\n")
      return
    end

    hrefs = []

    # Looks like a valid document! Let's parse it for links
    doc.search("//a[@href]").each do |e|
      hrefs << e.get_attribute("href")
    end

    if @options[:search_in_comments]
      # Let's also look for commented-out URIs
      doc.search("//comment()").each do |e|
        e.to_html.scan(/https?:\/\/[^\s\"]*/) { |url| hrefs << url; }
      end
    end

    hrefs.each do |href|
      # Skip mailto links
      next if href =~ /^mailto:/

      # If we're dealing with a host-relative URL (e.g. <img src="/foo/bar.jpg">), absolutify it.
      if href.to_s =~ /^\//
        href = uri.scheme + "://" + uri.host + href.to_s
      end

      # If we're dealing with a path-relative URL, make it relative to the current directory.
      unless href.to_s =~ /[a-z]+:\/\//
        # Take everything up to the final / in the path to be the current directory.
        if uri.path =~ /\//
          /^(.*)\//.match(uri.path)
          path = $1
          # If we're on the homepage, then we don't need a path.
        else
          path = ""
        end
        href = uri.scheme + "://" + uri.host + path + "/" + href.to_s
      end

      # At this point, we should have an absolute URL regardless of
      # its original format.

      # Strip hash links
      if (@options[:ignore_hash])
        href.gsub!(/(#.*?)$/, '')
      end

      # Strip query strings
      if (@options[:ignore_query_string])
        href.gsub!(/(\?.*?)$/, '')
      end

      begin
        href_uri = URI.parse(href)
      rescue
        # No harm in this — if we can't parse it as a URI, it probably isn't one (`javascript:` links, etc.) and we can safely ignore it.
        next
      end

      next if href_uri.host != uri.host
      next unless href_uri.scheme =~ /^https?$/

      yield href
    end
  end

  def spider(&block)
    Parallel.in_threads(@options[:threads]) { |thread_number|
      # We've crawled too many pages
      next if @pages_hit > @options[:num_pages] && @options[:num_pages] >= 0

      while @to_visit.length > 0 do
        begin
          url = @to_visit.pop
        end while (@visited.include? url)

        crawl_page(url)
      end
    }
  end
end

