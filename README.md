# Statusio::Rb

Ruby library wrapper for Status.io

Ruby library wrapper for Status.io - A Complete Status Platform - Status pages, incident tracking, subscriber notifications and more

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'statusio'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install statusio

## Usage

```ruby
# Sign up an account and get your api_id, api_key from developer tab
statusioclient = StatusioClient.new(api_key, api_id)
```

To work with component method

To work with maintenance methods

To work with subscriber methods

To work with metric methods

Please refer to Status.io API v2 for more details.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/statusio-rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

