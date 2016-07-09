require "pry"
require "refile/mini_magick"
require "phashion"

describe Refile::MiniMagick do
  let(:portrait) { Tempfile.new(["portrait", ".jpg"]) }
  let(:landscape) { Tempfile.new(["landscape", ".jpg"]) }

  matcher :be_similar_to do |expected|
    match do |actual|
      a = Phashion::Image.new(expected)
      b = Phashion::Image.new(actual)
      @distance = a.distance_from(b).abs
      @distance < allowed_distance
    end

    failure_message do
      "perceptual hash distance between images should be < #{allowed_distance} but was #{@distance}"
    end

    def allowed_distance
      2
    end
  end

  matcher :have_dimensions do |expected|
    match do |path|
      @actual = `identify -format '%wx%h' #{path}`
      actual == expected
    end

    failure_message do
      "expected image dimensions to be #{expected} but was #{@actual}"
    end
  end

  def fixture_path(name)
    File.expand_path("./fixtures/#{name}", File.dirname(__FILE__))
  end

  before do
    FileUtils.cp(fixture_path("portrait.jpg"), portrait.path)
    FileUtils.cp(fixture_path("landscape.jpg"), landscape.path)
  end

  describe "#convert" do
    it "changes the image format" do
      file = Refile::MiniMagick.new(:convert).call(portrait, "png")
      expect(`identify #{file.path}`).to match(/PNG/)
    end

    # it "yields the command object" do
    #   expect { |b| Refile::MiniMagick.new(:convert).call(portrait, "png", &b) }
    #     .to yield_with_args(MiniMagick::Tool)
    # end
  end

  describe "#limit" do
    it "resizes the image up to a given limit" do
      file = Refile::MiniMagick.new(:limit).call(portrait, "400", "400")
      expect(file.path).to have_dimensions('300x400')
    end

    it "does not resize the image if it is smaller than the limit" do
      file = Refile::MiniMagick.new(:limit).call(portrait, "1000", "1000")
      expect(file.path).to have_dimensions('600x800')
    end

    it "produces correct image" do
      file = Refile::MiniMagick.new(:limit).call(portrait, "400", "400")
      expect(file.path).to be_similar_to(fixture_path("limit.jpg"))
    end

    # it "yields the command object" do
    #   expect { |b| Refile::MiniMagick.new(:limit).call(portrait, "400", "400", &b) }
    #     .to yield_with_args(MiniMagick::Tool)
    # end
  end

  describe "#fit" do
    it "resizes the image to fit given dimensions" do
      file = Refile::MiniMagick.new(:fit).call(portrait, "400", "400")
      expect(file.path).to have_dimensions('300x400')
    end

    it "enlarges image if it is smaller than given dimensions" do
      file = Refile::MiniMagick.new(:fit).call(portrait, "1000", "1000")
      expect(file.path).to have_dimensions('750x1000')
    end

    it "produces correct image" do
      file = Refile::MiniMagick.new(:fit).call(portrait, "400", "400")
      expect(file.path).to be_similar_to(fixture_path("fit.jpg"))
    end

    # it "yields the command object" do
    #   expect { |b| Refile::MiniMagick.new(:fit).call(portrait, "400", "400", &b) }
    #     .to yield_with_args(MiniMagick::Tool)
    # end
  end

  describe "#fill" do
    it "resizes and crops the image to fill out the given dimensions" do
      file = Refile::MiniMagick.new(:fill).call(portrait, "400", "400")
      expect(file.path).to have_dimensions('400x400')
    end

    it "enlarges image and crops it if it is smaller than given dimensions" do
      file = Refile::MiniMagick.new(:fill).call(portrait, "1000", "1000")
      expect(file.path).to have_dimensions('1000x1000')
    end

    it "produces correct image" do
      file = Refile::MiniMagick.new(:fill).call(portrait, "400", "400")
      expect(file.path).to be_similar_to(fixture_path("fill.jpg"))
    end

    # it "yields the command object" do
    #   expect { |b| Refile::MiniMagick.new(:fill).call(portrait, "400", "400", &b) }
    #     .to yield_with_args(MiniMagick::Tool)
    # end
  end

  describe "#pad" do
    it "resizes and fills out the remaining space to fill out the given dimensions" do
      file = Refile::MiniMagick.new(:pad).call(portrait, "400", "400", "red")
      expect(file.path).to have_dimensions('400x400')
    end

    it "enlarges image and fills out the remaining space to fill out the given dimensions" do
      file = Refile::MiniMagick.new(:pad).call(portrait, "1000", "1000", "red")
      expect(file.path).to have_dimensions('1000x1000')
    end

    it "produces correct image" do
      file = Refile::MiniMagick.new(:pad).call(portrait, "400", "400", "red", format: "png")
      expect(file.path).to be_similar_to(fixture_path("pad.jpg"))
    end

    it "produces correct image when enlarging" do
      file = Refile::MiniMagick.new(:pad).call(landscape, "1000", "1000", "green")
      expect(file.path).to be_similar_to(fixture_path("pad-large.jpg"))
    end

    # it "yields the command object" do
    #   expect { |b| Refile::MiniMagick.new(:pad).call(portrait, "400", "400", &b) }
    #     .to yield_with_args(MiniMagick::Tool)
    # end
  end
end
