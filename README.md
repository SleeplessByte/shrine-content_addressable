# shrine-content_addressable
[![Build Status](https://travis-ci.com/SleeplessByte/shrine-content_addressable.svg?branch=master)](https://travis-ci.com/SleeplessByte/content_addressable)
[![Gem Version](https://badge.fury.io/rb/shrine-content_addressable.svg)](https://badge.fury.io/rb/shrine-content_addressable)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

Generate content addressable locations for shrine uploads.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'shrine-content_addressable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install shrine-content_addressable

## Usage

This plugin depends on the `signature` plugin:

```Ruby
require 'shrine/plugins/content_addressable'
require 'shrine/plugins/signature'

class MyUploader < Shrine
  plugin :signature
  plugin :content_addressable, hash: :sha256, prefix: '/'
end
```

Currently you can enter `:md5`, `:sha`, `:sha256` and `:sha512` for `hash:`. If you have a different algorithm that is
correctly supported by the `signature` plugin, and has a `multihash` code, add the multihash code mapping:

```Ruby
# Let's say the signature plugin starts supporting blake 2b as :blake2_b,
#   the multihash code is 'blake2b'
plugin :content_addressable, hash: :blake2_b, multihash: 'blake2b'
```

### ContentAddressable IO
Since a content-addressable stored file is the same across whichever storage, it *MUST* not matter what storage the file
is accessed from when it comes to reading. A wrapper is provided so files can be looked up by their content-addressable
id / hash, instead of a data hash (default for Shrine).

```Ruby
require 'content_addressable_file'

# You currently need to register the storages
ContentAddressableFile.register_storage(lookup, lookup, lookup)

# You can disallow deletion using
ContentAddressableFile.register_read_only_storage(lookup, lookup, lookup) 

file = ContentAddressableFile.new(content_addressable_hash)

# => file methods like open, rewind, read, close and eof? are available
# => file.url gives the first url that exists
# => file.exists? is true if it exists in any storage
# => file.delete attempts to delete it from ALL storages 
```

To reset known storages use:
```Ruby
ContentAddressableFile.reset
```

In a later version registration might be automatic. A lookup storage needs to respond to:
```Ruby
lookup = Shrine::Storage::Memory.new
id = content_addressable_hash

lookup.open(id) # IO.open
lookup.exists?(id) # true if storage has it (and can open)

# optional
lookup.url(id) # url to the io (only if storage has it)
lookup.delete(id) # delete from storage
lookup.download(id) # download the io
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `shrine-configurable_storage.gemspec.rb`, and then run `bundle exec rake release`, which will create
a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [SleeplessByte/shrine-configurable_storage](https://github.com/SleeplessByte/shrine-configurable_storage).
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Shrine::ConfigurableStorage project’s codebases, issue trackers, chat rooms and mailing
lists is expected to follow the [code of conduct](https://github.com/SleeplessByte/shrine-configurable_storage/blob/master/CODE_OF_CONDUCT.md).
