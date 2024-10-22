# frozen_string_literal: true

require "rake/clean"
CLOBBER.include "pkg"

require "bundler/gem_helper"
Bundler::GemHelper.install_tasks(name: "json")

require "rake/testtask"

# desc "Generate parser with ragel"
# task :ragel => [EXT_PARSER_SRC, JAVA_PARSER_SRC]

which = lambda { |c|
  w = `which #{c}`
  break w.chomp unless w.empty?
}

RAGEL_CODEGEN = if RUBY_PLATFORM =~ /mingw|mswin/
  # cleans up Windows CI output
  %w[ragel].find(&which)
else
  %w[rlcodegen rlgen-cd ragel].find(&which)
end

EXT_ROOT_DIR      = 'ext/json/ext'
EXT_PARSER_DIR    = "#{EXT_ROOT_DIR}/parser"
RAGEL_PATH        = "#{EXT_PARSER_DIR}/parser.rl"
EXT_PARSER_SRC    = "#{EXT_PARSER_DIR}/parser.c"

JAVA_DIR            = "java/src/json/ext"
JAVA_RAGEL_PATH     = "#{JAVA_DIR}/Parser.rl"
JAVA_PARSER_SRC     = "#{JAVA_DIR}/Parser.java"

file JAVA_PARSER_SRC => JAVA_RAGEL_PATH do
  cd JAVA_DIR do
    if RAGEL_CODEGEN == 'ragel'
      sh "ragel Parser.rl -J -o Parser.java"
    else
      sh "ragel -x Parser.rl | #{RAGEL_CODEGEN} -J"
    end
  end
end

file EXT_PARSER_SRC => RAGEL_PATH do
  cd EXT_PARSER_DIR do
    if RAGEL_CODEGEN == 'ragel'
      sh "ragel parser.rl -G2 -o parser.c"
    else
      sh "ragel -x parser.rl | #{RAGEL_CODEGEN} -G2"
    end
    src = File.read("parser.c").gsub(/[ \t]+$/, '')
    src.gsub!(/^static const int (JSON_.*=.*);$/, 'enum {\1};')
    src.gsub!(/^(static const char) (_JSON(?:_\w+)?_nfa_\w+)(?=\[\] =)/, '\1 MAYBE_UNUSED(\2)')
    src.gsub!(/0 <= ([\( ]+\*[\( ]*p\)+) && \1 <= 31/, "0 <= (signed char)(*(p)) && (*(p)) <= 31")
    src[0, 0] = "/* This file is automatically generated from parser.rl by using ragel */"
    File.open("parser.c", "w") {|f| f.print src}
  end
end

if RUBY_ENGINE == 'ruby'
  require 'rake/extensiontask'

  spec_path = File.join(__dir__, "json.gemspec")
  spec = eval(File.read(spec_path), binding, spec_path)

  Rake::ExtensionTask.new("json/ext/parser", spec) do |ext|
    ext.ext_dir = 'ext/json/ext/parser'
  end

  task "compile:json/ext/parser" => EXT_PARSER_SRC

  Rake::ExtensionTask.new("json/ext/generator", spec) do |ext|
    ext.ext_dir = 'ext/json/ext/generator'
  end
elsif RUBY_ENGINE == 'jruby'
  ENV['JAVA_HOME'] ||= [
    '/usr/local/java/jdk',
    '/usr/lib/jvm/java-6-openjdk',
    '/Library/Java/Home',
  ].find { |c| File.directory?(c) }
  if ENV['JAVA_HOME']
    warn " *** JAVA_HOME is set to #{ENV['JAVA_HOME'].inspect}"
    ENV['PATH'] = ENV['PATH'].split(/:/).unshift(java_path = "#{ENV['JAVA_HOME']}/bin") * ':'
    warn " *** java binaries are assumed to be in #{java_path.inspect}"
  else
    warn " *** JAVA_HOME was not set or could not be guessed!"
    exit 1
  end

  JAVA_SOURCES        = FileList["#{JAVA_DIR}/*.java"]
  JAVA_CLASSES        = []
  JRUBY_PARSER_JAR    = File.expand_path("lib/json/ext/parser.jar")
  JRUBY_GENERATOR_JAR = File.expand_path("lib/json/ext/generator.jar")

  JRUBY_JAR = File.join(RbConfig::CONFIG["libdir"], "jruby.jar")
  if File.exist?(JRUBY_JAR)
    JAVA_SOURCES.each do |src|
      classpath = (Dir['java/lib/*.jar'] << 'java/src' << JRUBY_JAR) * ':'
      obj = src.sub(/\.java\Z/, '.class')
      file obj => src do
        sh 'javac', '-classpath', classpath, '-source', '1.8', '-target', '1.8', src
      end
      JAVA_CLASSES << obj
    end
  else
    warn "WARNING: Cannot find jruby in path => Cannot build jruby extension!"
  end

  desc "Compiling jruby extension"
  task :compile => [JAVA_PARSER_SRC] + JAVA_CLASSES

  desc "Package the jruby gem"
  task :jruby_gem => :create_jar do
    sh 'gem build json.gemspec'
    mkdir_p 'pkg'
    mv "json-#{PKG_VERSION}.gem", "pkg/json-#{PKG_VERSION}-java.gem"
  end

  desc "Testing library (jruby)"
  task :"test:ext" => :create_jar

  file JRUBY_PARSER_JAR => :compile do
    cd 'java/src' do
      parser_classes = FileList[
        "json/ext/ByteListTranscoder*.class",
        "json/ext/OptionsReader*.class",
        "json/ext/Parser*.class",
        "json/ext/RuntimeInfo*.class",
        "json/ext/StringDecoder*.class",
        "json/ext/Utils*.class"
      ]
      sh 'jar', 'cf', File.basename(JRUBY_PARSER_JAR), *parser_classes
      mv File.basename(JRUBY_PARSER_JAR), File.dirname(JRUBY_PARSER_JAR)
    end
  end

  desc "Create parser jar"
  task :create_parser_jar => JRUBY_PARSER_JAR

  file JRUBY_GENERATOR_JAR => :compile do
    cd 'java/src' do
      generator_classes = FileList[
        "json/ext/ByteListTranscoder*.class",
        "json/ext/OptionsReader*.class",
        "json/ext/Generator*.class",
        "json/ext/RuntimeInfo*.class",
        "json/ext/StringEncoder*.class",
        "json/ext/Utils*.class"
      ]
      sh 'jar', 'cf', File.basename(JRUBY_GENERATOR_JAR), *generator_classes
      mv File.basename(JRUBY_GENERATOR_JAR), File.dirname(JRUBY_GENERATOR_JAR)
    end
  end

  desc "Create generator jar"
  task :create_generator_jar => JRUBY_GENERATOR_JAR

  desc "Create parser and generator jars"
  task :create_jar => [ :create_parser_jar, :create_generator_jar ]

  desc "Build all gems and archives for a new release of the jruby extension."
  task :build => [ :clean, :version, :jruby_gem ]

  task :release => :build
end

namespace :test do
  task :setup_pure do
    ENV["JSON"] = "pure"
  end
  
  Rake::TestTask.new(:pure) do |t|
    t.libs << "test/lib"
    t.test_files = FileList['test/**/*_test.rb']
    t.options = "-v"
  end
  task :pure => :setup_pure

  task :setup_ext do
    ENV["JSON"] = "ext"
  end

  Rake::TestTask.new(:ext) do |t|
    t.libs << "test/lib"
    t.test_files = FileList['test/**/*_test.rb']
    t.options = "-v"
  end
  task :ext => :setup_ext
end

task test: %i(test:pure test:ext)

task :default => :test
task :test => :compile
