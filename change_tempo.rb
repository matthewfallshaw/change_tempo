#!/usr/bin/env ruby

# Increase the tempo of all tracks in the 'Podcasts' playlist in iTunes
# (update state is stored in the mp3 'comments' tag, and already altered tracks
# will not be re-fiddled, so running this multiple times shouldn't hurt)
#
# === Dependencies:
#
# * sudo port install soundtouch ruby rb-rubygems
# ** (you can get MacPorts from http://www.macports.org/, which'll make the port command work)
# * sudo gem install activesupport rb-appscript
#
# === Install:
# 
# Put this somewhere sensible (like ~/bin/change_tempo) and run it regularly, by, say:
#   crontab -e
#   15 3 * * * ~/bin/change_tempo --speedup 20 --playlist new-podcasts > ~/log/change_tempo.log

%w[rubygems activesupport appscript tempfile].each {|l| require l }

class Podcast

  @@problems = []
  cattr_reader :problems
  cattr_accessor :playlist, :speedup

  self.speedup ||= 25
  self.playlist ||= "Podcasts"
  class << self
    def iTunes
      @itunes ||= Appscript.app("iTunes")
    end
    def count
      all_podcast_refs.size
    end
    def all_podcasts(playlist = self.playlist)
      all_podcast_refs(playlist).collect {|p| new(p) }.select {|p| p.mp3? }
    end
    def all_slow_podcasts(playlist = self.playlist)
      all_podcasts(playlist).select {|p| p.slow? }
    end
    def playlist_count
      all_podcast_refs.size
    end

    protected

    def all_podcast_refs(playlist = self.playlist)
      begin
        iTunes.playlists[playlist].tracks.get.select {|p| p.exists }
      rescue Appscript::CommandError
        []
      end
    end
  end

  # Instance methods

  def initialize(podcast_ref, speedup = self.speedup)
    @podcast_ref = podcast_ref
    self.speedup = speedup
  end

  def ref
    @podcast_ref
  end

  # Attributes
  %w[name comment].each do |prop|
    define_method(prop.to_sym) do
      ref.send(:"#{prop}").get
    end
    define_method(:"#{prop}=") do |value|
      ref.send(:"#{prop}").set(value)
    end
  end
  def location
    ref.location
  end
  def path
    location.get.path
  end
  def safe_path
    escape_filename(path)
  end
  def mp3?
    begin
      File.extname(path) == ".mp3"
    rescue Appscript::CommandError, AE::MacOSError => e
      false
    end
  end
  def slow?
    not comment.match(/\{\{\{change_tempo:\+\d+\}\}\}/)
  end

  def speedup=(value)
    raise(ArgumentError, "speedup should be an integer percentage above 0.") unless
      value.respond_to?(:to_i) && value.to_i >= 1
    @speedup = value.to_i
  end
  def speedup
    self.class.speedup || @speedup
  end

  def change_tempo(cent = self.speedup)
    begin
      raise(RuntimeError, "Not an mp3 - aborting.") unless mp3?
      raise(RuntimeError, "Already fast - aborting.") unless slow?
      slow_wav = to_slow_wav
      fast_wav = soundstretch(slow_wav, cent)
      cleanup(slow_wav)
      fast_mp3 = to_mp3(fast_wav)
      cleanup(fast_wav)
      copy_tags_to(fast_mp3)
      overwrite_self_with(fast_mp3)
      update_comment_with_speedup(cent)
    rescue RuntimeError => e
      @@problems << e
    ensure
      cleanup(slow_wav, fast_wav, fast_mp3)
    end
  end

  protected

  def to_slow_wav
    # lame --silent --decode <mp3> <slow-wav>
    filename = tempfile_path("slow.wav")
    cmd("lame --silent --decode #{safe_path} #{filename}")
    return filename
  end
  def soundstretch(wav, cent)
    # soundstretch <slow-wav> <fast-wav> -tempo=+70
    filename = tempfile_path("fast.wav")
    cmd("soundstretch #{wav} #{filename} -tempo=+#{cent}")
    return filename
  end
  def to_mp3(wav)
    # lame --silent -h <fast-wav> <fast-mp3>
    filename = tempfile_path("fast.mp3")
    cmd("lame --silent -h #{wav} #{filename}")
    return filename
  end
  def copy_tags_to(mp3)
    # id3cp <mp3> <fast-mp3>
    cmd("id3cp #{safe_path} #{mp3}")
    return nil
  end
  def overwrite_self_with(mp3)
    # mv <fast-mp3> <mp3>
    FileUtils.mv(unescape_filename(mp3), path)
    return nil
  end
  def update_comment_with_speedup(cent)
    # update comment and ensure itunes has noticed new file
    # touch iTunes db for changes
    new_comment = ""
    unless slow?
      raise RuntimeError, "Erm... it looks like we've just double sped up a podcast. Sorry about that."
    else
      new_comment = "{{{change_tempo:+#{cent}}}}" << self.comment
    end
    self.comment = new_comment
    return new_comment
  end
  def cleanup(*files)
    # rm <file>
    files.compact.each do |file|
      FileUtils.rm(file) if File.exist?(file)
      FileUtils.rm(unescape_filename(file)) if File.exist?(unescape_filename(file))
    end
  end

  private

  def tempfile_path(ext)
    escape_filename(Tempfile.new("#{object_id}_#{ext}").path)
  end
  def escape_filename(filename)
    filename.gsub(/(\W)/,'\\\\\1')
  end
  def unescape_filename(filename)
    filename.gsub(/\\/,'')
  end
  def cmd(command_string)
    puts command_string
    puts `#{command_string}`
    exitstatus = $?.exitstatus
    raise(RuntimeError, $?) unless exitstatus == 0
  end
end

if __FILE__ == $0
  require 'optparse'

  opts = OptionParser.new do |opts|
    opts.banner = "Usage: #$0 [options]"
    opts.separator ""
    opts.separator "Updates any mp3 files in the default (or named) iTunes playlist by the default or named tempo."
    opts.separator ""
    opts.separator "Specific options:"
    opts.on("-p", "--playlist PLAYLIST", "Convert unconverted mp3s in PLAYLIST") do |p|
      Podcast.playlist = p
    end
    opts.on("-s", "--speedup TEMPO", Integer, "Increase tempo by TEMPO (as a percentage)") do |c|
      Podcast.speedup = c
    end
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end

    begin
      opts.parse!(ARGV)
    rescue OptionParser::InvalidOption => e
      puts e.message
      puts
      puts opts
      exit
    end
  end

  puts "Running with playlist:#{Podcast.playlist} (#{Podcast.playlist_count} mp3s) and speedup:#{Podcast.speedup}..."

  Podcast.all_slow_podcasts.each do |p|
    p.change_tempo
  end
  $stderr.puts Podcast.problems.inspect unless Podcast.problems.empty?
end
