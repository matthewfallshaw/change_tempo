%w[ spec rubygems ruby-debug ]
require File.join(File.dirname(__FILE__), '../change_tempo')

describe Podcast do
  describe "class methods" do
    it "should have a speedup accessor" do
      Podcast.speedup = 53
      Podcast.speedup.should == 53
    end
    it "should have a playlist accessor" do
      Podcast.playlist = "some playlist"
      Podcast.playlist.should == "some playlist"
    end
    it "should have a problems reader" do
      lambda { Podcast.problems }.should_not raise_error
    end
    it "should have a playlist_count" do
      Podcast.stub!(:all_podcast_refs).and_return([1,2,3])

      Podcast.playlist_count.should == 3
    end
  end

  describe "command line arguments" do
    it "should set Podcast.playlist from playlist"
    it "should set Podcast.speedup from speedup"
  end

  describe "config file config" do
    it "should use config.yml if present and no command line arguments override those settings"
    it "should not use config.yml if command line arguments override those settings"
    it "should set Podcast.playlist from playlist"
    it "should set Podcast.speedup from speedup"
  end
end
