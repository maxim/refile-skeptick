require "refile"
require "refile/skeptick/version"
require "skeptick/core"

module Refile
  # Processes images via Skeptick, resizing cropping and padding them.
  class Skeptick
    # @param [Symbol] method        The method to invoke on {#call}
    def initialize(method)
      @method = method
    end

    # This would normally be named `convert` and included, this avoids collision
    # with existing method `convert` that Refile depends on.
    def skeptick_convert(*args, &block)
      ::Skeptick::Convert.new(self, *args, &block)
    end

    def path_for_format(path, format = nil)
      format ? path.sub(/\.[^.]+\z/, ".#{format.to_s.downcase}") : path
    end

    # Changes the image encoding format to the given format
    #
    # @see http://www.imagemagick.org/script/command-line-options.php#format
    # @param [Skeptick::Convert] img      the image to convert
    # @param [String] format              the format to convert to
    # @yield [MiniMagick::Tool::Mogrify, MiniMagick::Tool::Convert]
    # @return [void]
    def convert(img, format, &block)
      path = img.is_a?(::Skeptick::Convert) ? img.shellwords[1] : img
      dest_path = path_for_format(path, format)
      skeptick_convert(img, to: dest_path)
    end

    # Resize the image to fit within the specified dimensions while retaining
    # the original aspect ratio. Will only resize the image if it is larger
    # than the specified dimensions. The resulting image may be shorter or
    # narrower than specified in either dimension but will not be larger than
    # the specified values.
    #
    # @param [Skeptick::Convert] img      the image to convert
    # @param [#to_s] width                the maximum width
    # @param [#to_s] height               the maximum height
    # @yield [MiniMagick::Tool::Mogrify, MiniMagick::Tool::Convert]
    # @return [void]
    def limit(img, width, height, &block)
      img = skeptick_convert(img, &block) if block_given?

      skeptick_convert(img) do
        set :resize, "#{width}x#{height}>"
      end
    end

    # Resize the image to fit within the specified dimensions while retaining
    # the original aspect ratio. The image may be shorter or narrower than
    # specified in the smaller dimension but will not be larger than the
    # specified values.
    #
    # @param [Skeptick::Convert] img      the image to convert
    # @param [#to_s] width                the width to fit into
    # @param [#to_s] height               the height to fit into
    # @yield [MiniMagick::Tool::Mogrify, MiniMagick::Tool::Convert]
    # @return [void]
    def fit(img, width, height, &block)
      img = skeptick_convert(img, &block) if block_given?

      skeptick_convert(img) do
        set :resize, "#{width}x#{height}"
      end
    end

    # Resize the image so that it is at least as large in both dimensions as
    # specified, then crops any excess outside the specified dimensions.
    #
    # The resulting image will always be exactly as large as the specified
    # dimensions.
    #
    # By default, the center part of the image is kept, and the remainder
    # cropped off, but this can be changed via the `gravity` option.
    #
    # @param [Skeptick::Convert] img      the image to convert
    # @param [#to_s] width                the width to fill out
    # @param [#to_s] height               the height to fill out
    # @param [String] gravity             which part of the image to focus on
    # @yield [MiniMagick::Tool::Mogrify, MiniMagick::Tool::Convert]
    # @return [void]
    # @see http://www.imagemagick.org/script/command-line-options.php#gravity
    def fill(img, width, height, gravity = "Center", &block)
      # We use `convert` to work around GraphicsMagick's absence of "gravity"
      img = skeptick_convert(img, &block) if block_given?

      skeptick_convert(img) do
        set :resize, "#{width}x#{height}^"
        set :gravity, gravity
        set :extent, "#{width}x#{height}"
      end
    end

    # Resize the image to fit within the specified dimensions while retaining
    # the original aspect ratio in the same way as {#fill}. Unlike {#fill} it
    # will, if necessary, pad the remaining area with the given color, which
    # defaults to transparent where supported by the image format and white
    # otherwise.
    #
    # The resulting image will always be exactly as large as the specified
    # dimensions.
    #
    # By default, the image will be placed in the center but this can be
    # changed via the `gravity` option.
    #
    # @param [Skeptick::Convert] img      the image to convert
    # @param [#to_s] width                the width to fill out
    # @param [#to_s] height               the height to fill out
    # @param [string] background          the color to use as a background
    # @param [string] gravity             which part of the image to focus on
    # @yield [MiniMagick::Tool::Mogrify, MiniMagick::Tool::Convert]
    # @return [void]
    # @see http://www.imagemagick.org/script/color.php
    # @see http://www.imagemagick.org/script/command-line-options.php#gravity
    def pad(img, width, height, background = "transparent", gravity = "Center", &block)
      # We use `convert` to work around GraphicsMagick's absence of "gravity"
      img = skeptick_convert(img, &block) if block_given?

      skeptick_convert(img) do
        set :resize, "#{width}x#{height}"
        set :background,
          background == 'transparent' ? 'rgba(255, 255, 255, 0.0)' : background
        set :gravity, gravity
        set :extent, "#{width}x#{height}"
      end
    end

    # Process the given file. The file will be processed via one of the
    # instance methods of this class, depending on the `method` argument passed
    # to the constructor on initialization.
    #
    # If the format is given it will convert the image to the given file format.
    #
    # @param [Tempfile] file        the file to manipulate
    # @param [String] format        the file format to convert to
    # @return [File]                the processed file
    def call(file, *args, format: nil, &block)
      img = skeptick_convert(file.path, to: file.path)
      cmd = send(@method, img, *args, &block)

      if cmd.shellwords.last == ::Skeptick::Convert::DEFAULT_OUTPUT
        cmd = convert(cmd, format)
      end
      cmd.run

      ::File.open(cmd.shellwords.last, 'rb')
    end
  end
end

[:fill, :fit, :limit, :pad, :convert].each do |name|
  Refile.processor(name, Refile::Skeptick.new(name))
end