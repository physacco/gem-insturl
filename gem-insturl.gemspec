Gem::Specification.new do |s|
  s.name        = "gem-insturl"
  s.version     = "0.1.2"
  s.date        = "2013-05-13"

  s.summary     = "Gem plugin that installs a gem from a URL"
  s.description = <<EOF
The insturl command installs a gem from a URL.

Examples:
* gem **insturl** http://.../foo.git
* gem **insturl** http://.../foo.gem
* gem **insturl** http://.../foo.tar.gz
EOF

  s.authors     = ["physacco"]
  s.email       = ["physacco@gmail.com"]
  s.homepage    = "https://github.com/physacco/gem-insturl"
  s.license     = "MIT"

  s.files       = Dir["lib/**/*.rb"] + 
                  ["README.md", "VERSION", "gem-insturl.gemspec"]

  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = ">= 1.8.7"
end
