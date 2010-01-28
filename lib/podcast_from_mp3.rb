class PodcastFromMp3 < Podcast
  def initialize(mp3_file, speedup = @@speedup)
    @path = mp3_file
    @speedup = speedup
  end
  
  attr_accessor :path
  
  require 'id3lib'
  def tag
    @tag ||= ID3Lib::Tag.new(path)
  end
  def name
    tag.title
  end
  def comment
    tag.comment || ""
  end
  def comment=(value)
    tag.comment = value
  end
end
