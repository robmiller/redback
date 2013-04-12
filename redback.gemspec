Gem::Specification.new do |s|
  s.name = "redback"
  s.version = "0.2"

  s.add_runtime_dependency "hpricot", [">= 0.8.6"]
  s.add_runtime_dependency "parallel", [">= 0.6.4"]

  s.date = "2013-04-12"
  s.summary = "Spiders a website, pulling out a list of unique URLs."
  s.description = "Fetches a URL you give it and recursively searches for all URLs it can find, building up a list of unique URLs on the same hostname."

  s.authors = ["Rob Miller"]
  s.email = "rob@bigfish.co.uk"
  s.homepage = "https://github.com/robmiller/redback"

  s.executables << "redback"
  s.files = ["bin/redback", "lib/redback.rb"]
end
