# frozen_string_literal: true

require 'forwardable'

class ContentAddressableFile
  class ReadOnlyStorage
    extend Forwardable
    def_delegators :@storage,
                   :exists?, :download, :url, :class, :equal?, :eql?, :hash

    def initialize(storage)
      @storage = storage
    end
  end
end
