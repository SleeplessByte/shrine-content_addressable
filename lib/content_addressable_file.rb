# frozen_string_literal: true

require 'English'

class ContentAddressableFile

  class << self
    attr_accessor :storages

    def register_storage(*storage)
      self.storages = Array(storages).push(*storage)
      self
    end

    def reset
      self.storages = []
      self
    end
  end

  attr_reader :id

  def initialize(id)
    self.id = id
  end

  # Calls `#open` on the storages to open the uploaded file for reading.
  # Most storages will return a lazy IO object which dynamically
  # retrieves file content from the storage as the object is being read.
  #
  # If a block is given, the opened IO object is yielded to the block,
  # and at the end of the block it's automatically closed. In this case
  # the return value of the method is the block return value.
  #
  # If no block is given, the opened IO object is returned.
  #
  #     content_addressable.open #=> IO object returned by the storage
  #     content_addressable.read #=> "..."
  #     content_addressable.close
  #
  #     # or
  #
  #     content_addressable.open { |io| io.read }
  #     #=> "..."
  def open(*args)
    return to_io unless block_given?

    begin
      @io = pin_storage(:open, id, *args)
      yield @io
    ensure
      @io&.close
      @io = nil
    end
  end

  alias safe_open open

  # Calls `#download` on the storages if the storage that has the file
  # implements it, otherwise streams content into a newly created Tempfile.
  #
  # If the file exists in multiple storages, any that allows download will
  # be pinned.
  #
  # If a block is given, the opened Tempfile object is yielded to the
  # block, and at the end of the block it's automatically closed and
  # deleted. In this case the return value of the method is the block
  # return value.
  #
  # If no block is given, the opened Tempfile is returned.
  #
  #     content_addressable.download
  #     #=> #<File:/var/folders/.../20180302-33119-1h1vjbq.jpg>
  #
  #     # or
  #
  #     content_addressable.download { |tempfile| tempfile.read }
  #     # tempfile is deleted
  #     #=> "..."
  def download(*args)
    if any_storage(:respond_to?, :download)
      tempfile = pin_storage(:download, id, *args)
    else
      tempfile = Tempfile.new(['content-addressable', id], binmode: true)
      stream(tempfile, *args)
      tempfile.open
    end

    block_given? ? yield(tempfile) : tempfile
  ensure
    tempfile.close! if ($ERROR_INFO || block_given?) && tempfile
  end

  # Streams uploaded file content into the specified destination. The
  # destination object is given directly to `IO.copy_stream`, so it can
  # be either a path on disk or an object that responds to `#write`.
  #
  # If the uploaded file is already opened, it will be simply rewinded
  # after streaming finishes. Otherwise the uploaded file is opened and
  # then closed after streaming.
  #
  #     content_addressable.stream(StringIO.new)
  #     # or
  #     content_addressable.stream("/path/to/destination")
  def stream(destination, *args)
    if @io
      IO.copy_stream(io, destination)
      io.rewind
    else
      safe_open(*args) { |io| IO.copy_stream(io, destination) }
    end
  end

  # Part of complying to the IO interface. It delegates to the internally
  # opened IO object.
  def read(*args)
    io.read(*args)
  end

  # Part of complying to the IO interface. It delegates to the internally
  # opened IO object.
  def eof?
    io.eof?
  end

  # Part of complying to the IO interface. It delegates to the internally
  # opened IO object.
  def rewind
    io.rewind
  end

  # Part of complying to the IO interface. It delegates to the internally
  # opened IO object.
  def close
    io.close if @io
  end

  # Calls `#url` on the storage where the file is first found, forwarding any
  # given URL options.
  def url(**options)
    pin_storage(:url, id, **options)
  end

  # Calls `#exists?` on the storages, which checks whether the file exists
  # on any of the storages.
  def exists?
    pin_storage(:exists?, id)
  end

  # Calls `#delete` on the storages, which deletes the file from the
  # storage.
  def delete
    all_storages(:delete, id)
  end

  # Returns an opened IO object for the uploaded file.
  def to_io
    io
  end

  # Returns true if the other File has the same id
  def ==(other)
    other.is_a?(self.class) && id == other.id
  end
  alias eql? ==

  # Enables using File objects as hash keys.
  def hash
    [id].hash
  end

  # Returns the storage that this file was uploaded to.
  def storage
    pin_storage(:exists?, id) && @pin_storage
  end

  private

  attr_writer :id

  # Returns an opened IO object for the uploaded file by calling `#open`
  # on the storage.
  def io
    @io ||= safe_open(id)
  end

  # rubocop:disable Style/RescueModifier
  def all_storages(method, *args)
    self.class.storages.map do |storage|
      storage.send(method, *args) rescue next
    end
  end

  def any_storage(method, *args)
    self.class.storages.each do |storage|
      result = storage.send(method, *args) rescue next
      break result if result
    end
  end

  def pin_storage(method, *args)
    @pin_storage = self.class.storages.find do |storage|
      storage.send(:exists?, id) rescue next
    end

    @pin_storage&.send(method, *args)
  end
  # rubocop:enable Style/RescueModifier

end
