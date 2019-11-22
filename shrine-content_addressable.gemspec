# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'shrine-content_addressable'
  spec.version       = '0.4.0'
  spec.authors       = ['Derk-Jan Karrenbeld']
  spec.email         = ['derk-jan+github@karrenbeld.info']

  spec.license       = 'MIT'
  spec.summary       = 'Generate a content addressable location for shrine uploads'

  spec.metadata = {
    'bug_tracker_uri'   => 'https://github.com/SleeplessByte/shrine-content_addressable/issues',
    'changelog_uri'     => 'https://github.com/SleeplessByte/shrine-content_addressable/CHANGELOG.md',
    'homepage_uri'      => 'https://github.com/SleeplessByte/shrine-content_addressable',
    'source_code_uri'   => 'https://github.com/SleeplessByte/shrine-content_addressable'
  }

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = 'https://gems.sleeplessbyte.technology'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'multihashes', '~> 0.2.0'
  spec.add_dependency 'shrine', '>= 2.0.0', '<= 3.1.0'

  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'shrine-configurable_storage', '< 1.0.0'
  spec.add_development_dependency 'shrine-memory'
end
