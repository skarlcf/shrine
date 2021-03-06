# frozen_string_literal: true

class Shrine
  module Plugins
    # The `refresh_metadata` plugin allows you to re-extract metadata from an
    # uploaded file.
    #
    #     plugin :refresh_metadata
    #
    # It provides `UploadedFile#refresh_metadata!` method, which triggers
    # metadata extraction (calls `Shrine#extract_metadata`) with the uploaded
    # file opened for reading, and updates the existing metadata hash with the
    # results.
    #
    #     uploaded_file.refresh_metadata!
    #     uploaded_file.metadata # re-extracted metadata
    #
    # For remote storages this will make an HTTP request to open the file for
    # reading, but only the portion of the file needed for extracting each
    # metadata value will be downloaded.
    #
    # If the uploaded file is already open, it is passed to metadata extraction
    # as is.
    #
    #     uploaded_file.open do
    #       uploaded_file.refresh_metadata!
    #       # ...
    #     end
    module RefreshMetadata
      module FileMethods
        def refresh_metadata!(context = {})
          refreshed_metadata =
            if @io
              uploader.extract_metadata(self, context)
            else
              open { uploader.extract_metadata(self, context) }
            end

          @data = @data.merge("metadata" => metadata.merge(refreshed_metadata))
        end
      end
    end

    register_plugin(:refresh_metadata, RefreshMetadata)
  end
end
