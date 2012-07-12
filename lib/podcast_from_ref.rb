require 'appscript'
require File.dirname(__FILE__) + '/sdefToRBAppscriptModule'
Tunes = SDEFParser.makeModule("/Applications/iTunes.app")

class PodcastFromRef < Podcast

  class << self

    def iTunes
      @itunes ||= Appscript.app("iTunes", Tunes)
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

    protected

    def all_podcast_refs(playlist = self.playlist)
      begin
        iTunes.playlists[playlist].tracks.get.select {|p| p.exists }
      rescue Appscript::CommandError
        []
      end
    end
  end

  def initialize(ref, speedup = @@speedup)
    @podcast_ref = ref
    @speedup = speedup
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
  
end
