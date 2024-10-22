ENV["JSON_TEST"] = "1"

case ENV['JSON']
when 'pure'
  $:.unshift File.join(__dir__, '../../lib')
  require 'json/pure'
when 'ext', nil
  $:.unshift File.join(__dir__, '../../ext'), File.join(__dir__, '../../lib')
  require 'json/ext'
end

require 'test/unit'

unless defined?(Test::Unit::CoreAssertions)
  require "core_assertions"
  Test::Unit::TestCase.include Test::Unit::CoreAssertions
end
