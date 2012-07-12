#!/usr/bin/env ruby

require 'rubygems'
gem 'activesupport', '2.3.14'
require 'active_support'

file = __FILE__
file = File.expand_path(File.readlink(file), File.dirname(file)) while File.symlink?(file)
Dir[File.join(File.dirname(file), 'lib', '*')].each { |l| require l }

if __FILE__ == $0
  require 'optparse'

  opts = OptionParser.new do |opts|
    opts.banner = "Usage: #$0 [OPTION]... JOB..."
    opts.separator ""
    opts.separator "Shifts the tempo of unconverted mp3s by the default or named tempo."
    opts.separator "For JOBs that are iTunes playlists, updates any mp3 files in them. For JOBs that are mp3 files,"
    opts.separator "updates them."
    opts.separator ""
    opts.separator "Specific options:"
    opts.on("-s", "--speedup TEMPO", Integer, "Increase tempo by TEMPO (as a percentage).") do |c|
      Podcast.speedup = c
    end
    opts.on("-q", "--quiet", "Do not log messages to standard output.") do |c|
      Podcast.quiet = true
    end
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end

    begin
      opts.parse!(ARGV)
      

      unless ARGV.length >= 1
        puts opts
      end
      ARGV.each do |job|
        Podcast.process(job)
      end
      $stderr.puts Podcast.problems.inspect unless Podcast.problems.empty?
    rescue OptionParser::InvalidOption => e
      $stderr.puts e.message
      $stderr.puts
      $stderr.puts opts
      exit
    end
  end
end
