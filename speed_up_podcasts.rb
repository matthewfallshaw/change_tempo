#!/usr/bin/env ruby

# Increase the tempo of all tracks in the 'podcasts' playlist in iTunes
# (update state is stored in running this multiple times shouldn't hurt)
#
# Dependencies:
#   (you can get MacPorts from http://www.macports.org/, which'll make the port command work)
#   sudo port install soundtouch ruby rb-rubygems
#   sudo gem install activerecord activesupport rb-appscript
%w[rubygems activesupport appscript].each {|l| require l }

class Podcast

  @@problems = []

  class << self
    DEFAULT_PLAYLIST = "podcasts"
    def iTunes
      @itunes ||= Appscript.app("iTunes")
    end
    def each_podcast(playlist = DEFAULT_PLAYLIST)
      all_podcast_refs(playlist).each do |p|
        yield new(p)
      end
    end
    def each_slow_podcast(playlist = DEFAULT_PLAYLIST)
      all_podcast_refs(playlist).each do |p|
        podcast = new(p)
        yield podcast if podcast.slow?
      end
    end
    def count
      all_podcast_refs.size
    end
    def all_podcasts(playlist = DEFAULT_PLAYLIST)
      all_podcast_refs(playlist).collect {|p| new(p) }
    end
    def all_slow_podcasts(playlist = DEFAULT_PLAYLIST)
      all_podcasts(playlist).select {|p| p.slow? }
    end

    protected

    def all_podcast_refs(playlist)
      iTunes.playlists[playlist].tracks.get
    end
  end

  # Instance methods

  def initialize(podcast_ref, speedup = 70)
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
    File.extname(path) == ".mp3"
  end

  def slow?
    not comment.match(/\{\{\{change_tempo:\+\d+\}\}\}/)
  end

  attr_accessor :speedup
  def speedup=(value)
    raise(ArgumentError, "speedup should be an integer percentage above 0.") unless value.respond_to?(:to_i) && value.to_i >= 1
    @speedup = value.to_i
  end

  def change_tempo(cent = self.speedup)
    begin
      raise(RuntimeError, "Not an mp3 - aborting.") unless mp3?
      slow_wav = to_slow_wav
      fast_wav = soundstretch(slow_wav, cent)
      cleanup(slow_wav)
      fast_mp3 = to_mp3(fast_wav)
      cleanup(fast_wav)
      copy_tags_to(fast_mp3)
      overwrite_self_with(fast_mp3)
      update_comment_with_speedup
    rescue RuntimeError => e
      @@problems << e
    ensure
      cleanup(slow_wav, fast_wav, fast_mp3)
      puts @@problems.inspect unless @@problems.empty?
    end
  end

  protected

  def to_slow_wav
    # lame --decode <mp3> <slow-wav>
    filename = tempfile_path("slow.wav")
    cmd("lame --decode #{safe_path} #{filename}")
    return filename
  end
  def soundstretch(wav, cent)
    # soundstretch <slow-wav> <fast-wav> -tempo=+70
    filename = tempfile_path("fast.wav")
    cmd("soundstretch #{wav} #{filename} -tempo=+#{cent}")
    return filename
  end
  def to_mp3(wav)
    # lame -h <fast-wav> <fast-mp3>
    filename = tempfile_path("fast.mp3")
    cmd("lame -h #{wav} #{filename}")
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
  def update_comment_with_speedup
    # update comment and ensure itunes has noticed new file
    # touch iTunes db for changes
    new_comment = ""
    unless slow?
      raise RuntimeError, "Erm... it looks like we've just double sped up a podcast. Sorry about that."
    else
      new_comment = "{{{change_tempo:+#{speedup}}}}" << self.comment
    end
    self.comment = new_comment
    return new_comment
  end
  def cleanup(*files)
    # rm <file>
    files.each do |file|
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

  # TODO: accept command line playlist or speedup
  # TODO: accept playlist or speedup from $0.yml

  opts = OptionParser.new
  opts.on("-h", "--help") { "Usage: #{$0}\nUpdates any " }
  opts.parse(ARGV)

  Podcast.each_slow_podcast do |p|
    p.change_tempo
  end
end
