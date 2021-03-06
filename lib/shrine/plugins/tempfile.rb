class Shrine
  module Plugins
    # The `tempfile` plugin makes it easier to reuse a single copy of an
    # uploaded file on disk.
    #
    #     Shrine.plugin :tempfile
    #
    # The plugin provides the `UploadedFile#tempfile` method, which when called
    # on an open uploaded file will return a copy of its content on disk. The
    # first time the method is called the file content will cached into a
    # temporary file and returned. On any subsequent method calls the cached
    # temporary file will be returned directly. The temporary file is deleted
    # when the uploaded file is closed.
    #
    #     uploaded_file.open do
    #       # ...
    #       uploaded_file.tempfile #=> #<Tempfile:...> (file is cached)
    #       # ...
    #       uploaded_file.tempfile #=> #<Tempfile:...> (cache is returned)
    #       # ...
    #     end # tempfile is deleted
    #
    #     # OR
    #
    #     uploaded_file.open
    #     # ...
    #     uploaded_file.tempfile #=> #<Tempfile:...> (file is cached)
    #     # ...
    #     uploaded_file.tempfile #=> #<Tempfile:...> (cache is returned)
    #     # ...
    #     uploaded_file.close # tempfile is deleted
    #
    # This plugin also modifies `Shrine.with_file` to call
    # `UploadedFile#tempfile` when the given IO object is an open
    # `UploadedFile`. Since `Shrine.with_file` is typically called on the
    # `Shrine` class directly, it's recommended to load this plugin globally.
    module Tempfile
      module ClassMethods
        def with_file(io)
          if io.is_a?(UploadedFile) && io.opened?
            # open a new file descriptor for thread safety
            File.open(io.tempfile.path, binmode: true) do |file|
              yield file
            end
          else
            super
          end
        end
      end

      module FileMethods
        def tempfile
          raise Error, "uploaded file must be opened" unless @io

          @tempfile ||= download
          @tempfile.rewind
          @tempfile
        end

        def close
          super

          @tempfile.close! if @tempfile
          @tempfile = nil
        end
      end
    end

    register_plugin(:tempfile, Tempfile)
  end
end
