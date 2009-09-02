require File.dirname(__FILE__) + '/../spec_helper'

describe Podcast do
  describe "class methods:" do
    before(:each) do
      Podcast.playlist = nil
    end

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
    it "should process playlists"
    it "should process single mp3 files"

    describe " #change_tempo" do
      describe "should abort on errors" do
        [:to_slow_wav, :soundstretch, :to_mp3, :copy_tags_to].each do |method|
          it "in #{method}"
        end
      end
    end
  end

  describe "instance methods:" do

  end

end
