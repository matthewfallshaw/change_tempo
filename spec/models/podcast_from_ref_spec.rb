require File.dirname(__FILE__) + '/../spec_helper'

describe PodcastFromRef do

  describe "instance methods:" do
    
    it "should infer path from location" do
      ref = mock("podcast_ref", :null_object => true)
      p = PodcastFromRef.new(ref)
      
      p.should_receive(:location).and_return(mock("location", :null_object => true))
      
      p.path
    end
    it "should infer location from ref" do
      ref = mock("podcast_ref", :null_object => true)
      p = PodcastFromRef.new(ref)
      
      ref.should_receive(:location)
      
      p.location
    end
    [:name, :comment].each do |prop|
      it "should infer #{prop} from ref" do
        ref = mock("podcast_ref", :null_object => true)
        p = PodcastFromRef.new(ref)

        ref.should_receive(prop).and_return(mock("getter", :null_object => true))

        p.send(prop)
      end
    end
  end

end
