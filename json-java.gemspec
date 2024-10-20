version = File.foreach(File.join(__dir__, "lib/json/version.rb")) do |line|
  /^\s*VERSION\s*=\s*'(.*)'/ =~ line and break $1
end rescue nil

spec = Gem::Specification.new do |s|
  s.name = "json"
  s.version = version

  s.summary = "JSON Implementation for Ruby"
  s.description = "A JSON implementation as a JRuby extension."
  s.licenses = ["Ruby"]
  s.author = "Daniel Luz"
  s.email = "dev+ruby@mernen.com"

  s.platform = 'java'

  s.files = Dir["lib/**/*", "COPYING", "LEGAL", "BSDL"]

  s.homepage = "https://ruby.github.io/json"
  s.metadata = {
      'bug_tracker_uri'   => 'https://github.com/ruby/json/issues',
      'changelog_uri'     => 'https://github.com/ruby/json/blob/master/CHANGES.md',
      'documentation_uri' => 'https://ruby.github.io/json/doc/index.html',
      'homepage_uri'      => s.homepage,
      'source_code_uri'   => 'https://github.com/ruby/json',
      'wiki_uri'          => 'https://github.com/ruby/json/wiki'
  }

  s.required_ruby_version = Gem::Requirement.new(">= 2.3")
end

if $0 == __FILE__
  Gem::Builder.new(spec).build
else
  spec
end
