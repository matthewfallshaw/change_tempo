class Podcast

  cattr_reader :problems
  cattr_accessor :speedup, :playlist, :file, :quiet

  @@problems = []
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
      all_podcast_refs(playlist).collect {|p| PodcastFromRef.new(p) }.select {|p| p.mp3? }
    end
    def all_slow_podcasts(playlist = self.playlist)
      all_podcasts(playlist).select {|p| p.slow? }
    end
    def playlist_count
      all_podcast_refs.size
    end
    
    def process(job)
      if File.exist?(job)
        log "Shifting file:#{job} with speedup:#{Podcast.speedup}..."

        PodcastFromMp3.new(job).change_tempo
      else
        log "Running with playlist:#{Podcast.playlist} (#{Podcast.playlist_count} mp3s) and speedup:#{Podcast.speedup}..."
        log "      (speedup #{Podcast.speedup} means moving the audio to #{Podcast.speedup + 100}% of it's normal speed)"

        Podcast.playlist = job
        Podcast.all_slow_podcasts.each do |p|
          p.change_tempo
        end
      end
    end

    def log(message)
      puts message unless quiet
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

  def initialize(podcast_ref_or_file_path, speedup = self.speedup)
    raise "You're trying to call #{self.class.to_s}#new. Don't. You want one of my subclasses."
  end
  
  # Attributes
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
    File.open(path, 'r') do |f|
      cmd("lame --silent --decode #{safe_path} #{filename}")
    end
    return filename
  end
  def soundstretch(wav, cent)
    # soundstretch <slow-wav> <fast-wav> -tempo=+70
    filename = tempfile_path("fast.wav")
    cmd("soundstretch #{wav} #{filename} -speech -tempo=+#{cent} 2>/dev/null")  # sucks to redirect stderr
                                                                                # but soundstretch always emits
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
    # FileUtils.mv(unescape_filename(mp3), path)
    FileUtils.cp(unescape_filename(mp3), path)
    FileUtils.rm(unescape_filename(mp3)) rescue nil  # this just started erroring, and I don't really care why
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
    log command_string
    log `#{command_string}`
    exitstatus = $?.exitstatus
    raise(RuntimeError, $?) unless exitstatus == 0
  end
  def log(message)
    self.class.log message
  end
end
