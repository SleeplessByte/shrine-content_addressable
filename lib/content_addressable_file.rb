# frozen_string_literal: true

require 'multihashes'
require 'set'

require 'content_addressable_file/acts_as_uploaded_file'
require 'content_addressable_file/shared_interface'

class ContentAddressableFile
  attr_reader :id

  # Creates a new content-addressable file wrapper that uses the given id as
  # content hash, assuming that it is a content addressable multihash
  #
  # @param [String] id the multihash that is the content-addressable
  #
  def initialize(id)
    self.id = id
  end

  include ActsAsUploadedFile
  include SharedInterface

  private

  attr_writer :id
end
