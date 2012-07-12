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
    it "should have a problems reader" do
      lambda { Podcast.problems }.should_not raise_error
    end
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

    Podcast.subclasses.each do |klass|
    #[PodcastFromMp3, PodcastFromRef].each do |klass|
      describe "#{klass}#speedup" do
        it "should inherit from class#speedup without argument" do
          Podcast.speedup = 42
          p = klass.new(:ref_or_file)
          p.speedup.should == 42
        end
      end
    end

  end

end
