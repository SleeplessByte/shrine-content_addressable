# frozen_string_literal: true

require 'content_addressable_file'
require 'content_addressable_file/shared_interface'

class Shrine
  module Plugins
    module ContentAddressable
      module FileMethods
        include ContentAddressableFile::SharedInterface

        def to_content_addressable!
          ContentAddressableFile.register_storage(storage)
          ContentAddressableFile.new(id)
        end
      end
    end
  end
end
