# redback

Redback is a Ruby spider (geddit?). Pass it a website, and it will begin
its many-legged crawl, scurrying across the site to pull out all the
unique URLs it can find.

Just like a terrifying real-life spider, redback aims to be fast: in
particular, it sends requests in parallel so one slow page won't slow
down your crawl.

## Installation

	$ gem install redback

## Usage

### Command line

	$ redback http://example.com/

…in which case it will print all the URLs it finds within the site
`http://example.com/`.

You can output he results to a file like this:

    $ redback http://example.com > output.txt
    
Or feed them to another command line tool like this:

    $ redback http://xkcd.com | grep xml

### Within Ruby

It can also be used as a library:

	require 'redback'

	Redback.new "http://example.com" { |url| puts url }

The `Redback.new` method accepts a URL and a block; the block will be
executed for each URL found.
