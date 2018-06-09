# shrine-content_addressable
[![Build Status](https://travis-ci.com/SleeplessByte/shrine-content_addressable.svg?branch=master)](https://travis-ci.com/SleeplessByte/content_addressable)
[![Gem Version](https://badge.fury.io/rb/shrine-content_addressable.svg)](https://badge.fury.io/rb/content_addressable)
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `shrine-configurable_storage.gemspec.rb`, and then run `bundle exec rake release`, which will create
a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SleeplessByte/shrine-configurable_storage.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Shrine::ConfigurableStorage project’s codebases, issue trackers, chat rooms and mailing
lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/shrine-configurable_storage/blob/master/CODE_OF_CONDUCT.md).
