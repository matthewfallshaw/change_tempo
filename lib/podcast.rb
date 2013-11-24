%w[rubygems tempfile].each {|l| require l }

class Podcast

  cattr_reader :problems
  cattr_accessor :speedup, :playlist, :file, :quiet

  @@problems = []
  self.speedup ||= 25
  self.playlist ||= "Podcasts"

  class << self
    
    def process(job)
      if File.exist?(job)
        log "Shifting file:#{job} with speedup:#{Podcast.speedup}..."

        PodcastFromMp3.new(job).change_tempo
      else
        PodcastFromRef.playlist = job
        log "Running with playlist:#{PodcastFromRef.playlist} (#{PodcastFromRef.playlist_count} mp3s) and speedup:#{PodcastFromRef.speedup}..."
        log "      (speedup #{PodcastFromRef.speedup} means moving the audio to #{PodcastFromRef.speedup + 100}% of it's normal speed)"
        PodcastFromRef.all_slow_podcasts.each do |p|
          p.change_tempo
        end
      end
    end

    def log(message)
      puts message unless quiet
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
      File.extname(path).downcase == ".mp3"
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
    assert_file_is_mp3!
    assert_file_not_already_processed!

    new_tempo = 1 + (cent/100.0)
    source_file = unescape_filename safe_path

    # use plain unix path, to solve problems with some iTunes playlist
    source_file_2 = unescape_filename tempfile_path("slow.mp3")
    FileUtils.cp(source_file, source_file_2)
    temp_file     = unescape_filename tempfile_path("slow2.mp3")

    process_1_file(source_file_2, temp_file, new_tempo)
    overwrite_source_file(temp_file, source_file)
    update_comment_with_speedup(cent)
  rescue RuntimeError => e
    @@problems << e
  ensure
      cleanup(temp_file)
  end

  private

  def assert_file_is_mp3!
    raise(RuntimeError, "Not an mp3 - aborting.") unless mp3?
  end
  def assert_file_not_already_processed!
    raise(RuntimeError, "Already fast - aborting.") unless slow?
  end


  def process_1_file(source, dest, new_tempo)
    File.open(path, 'r') do |f|
      cmd "sox #{source} #{dest} tempo -s #{new_tempo}"
      cmd "id3cp #{safe_path} #{dest}"
    end
  end

  def overwrite_source_file(temp_file, source_file)
    FileUtils.cp(temp_file, source_file)
    FileUtils.rm(unescape_filename(temp_file))
  end

  protected

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
    escape_filename(Tempfile.new(["#{object_id}", "#{ext}"]).path)
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
