class PodcastFromRef < Podcast
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