# Cogy

[![Build Status](https://api.travis-ci.org/skroutz/cogy.svg?branch=master)](https://travis-ci.org/skroutz/cogy)
[![Gem Version](https://badge.fury.io/rb/cogy.svg)](https://badge.fury.io/rb/cogy)
[![Inline docs](http://inch-ci.org/github/skroutz/cogy.svg)](http://inch-ci.org/github/skroutz/cogy)

Cogy integrates [Cog](https://operable.io/) with Rails
in a way that writing & deploying commands from your application is a breeze.

See the API documentation [here](http://www.rubydoc.info/github/skroutz/cogy).

## Status

Cogy is still in public alpha.

While we use it in production, it's still under heavy development.
This means that there are a few rough edges and some important bits are missing.

However we'd love any [feedback, suggestions or ideas](https://github.com/skroutz/cogy/issues/new).

## Why

Creating a ChatOps command that talks with a Rails app typically involves writing
a route, maybe a controller, an action and code to handle the command arguments
and options.

This is a tedious and repetitive task and involves a lot of boilerplate
code each time someone wants to add a new command.

Cogy is an opinionated library that provides a way to get rid of all the
repetitive work.

Writing a new command and deploying it is as simple as:

```ruby
# in cogy/my_commands.rb

on "foo", desc: "Echo a foo bar back at you!" do
  "@#{handle}: foo bar"
end
```

...and deploying! After a second or so, the command is ready to be used.

## How it works

Cogy is essentially three things:

1. An opinionated way to write, manage & ship commands: All Cogy commands are
   defined in your Rails app and end up invoking a [single executable](https://github.com/skroutz/cogy-bundle/blob/master/commands/cogy) within the
   Relay. Cogy also provides bundle versioning and dynamically generates the
   installable bundle config, which is also served by your Rails application
   and consumed by the [`cogy:install`](https://github.com/skroutz/cogy-bundle)
   command that installs the new Cogy-generated bundle when you deploy your
   application.
2. A library that provides the API for defining the commands. This library
   is integrated in your application via a Rails Engine that routes the incoming
   requests to their respective handlers. It also creates the `/inventory`
   endpoint, which serves the installable bundle configuration in YAML and can be
   consumed directly by the [`cogy:install`](https://github.com/skroutz/cogy-bundle) command.
3. A [Cog bundle](https://github.com/skroutz/cogy-bundle) that contains the
   [executable](https://github.com/skroutz/cogy-bundle/blob/master/commands/cogy)
   that all the commands end up invoking.
   It is placed inside the Relays and performs the requests to your application
   when a user invokes a command in the chat. It then posts the result back
   to the user. It also contains the `cogy:install` command for automating
   the task of installing the new bundle when a command is added/modified.

Take a look at the relevant [diagrams](diagrams/) for an illustration of how
Cogy works.

## Requirements

* [cogy bundle](https://github.com/skroutz/cogy-bundle)
* Ruby 2.1+
* Tested with Rails 4.2

## Install

Add it to your Gemfile:

```ruby
gem "cogy"
```

Then run `bundle install`

Next, run the generator:

```shell
$ bin/rails g cogy:install
```

This will create a sample command, mount the engine and add a sample
configuration initializer in your application.

## Usage

Defining a new command:

```ruby
# in cogy/commands.rb

on "foo", desc: "Echo a bar" do
  "bar"
end
```

This will print "bar" back to the user who calls `!foo` in Slack, for example.

Inside the block there are the following pre-defined helpers available:

* `#args`: an array containing the arguments passed to the command
* `#opts`: a hash containing the options passed to the command
* `#handle`: the chat handle of the user who called the command
* `#env`: a hash containing the Cogy environment, that is, every environment variable
  starting with 'COGY_' and set in the Relay

For instructions on defining your own helpers, see [Helpers](#helpers).

A more complete example:

```ruby
# in cogy/commands.rb
on "calc",
  args: [:a, :b],
  opts: { op: { type: "string", required: true } },
  desc: "Performs a calculation between numbers <a> and <b>",
  examples: "myapp:calc sum 1 2" do
  op = opts[:op].to_sym
  result = args.map(&:to_i).inject(&op)
  "Hello @#{user}, the result is: #{result}"
end
```

For more examples see the [test commands](https://github.com/skroutz/cogy/tree/master/test/dummy/cogy).


## Configuration

The configuration options provided are the following:

```ruby
# in config/initializers/cogy.rb

Cogy.configure do |config|
  # Used in the generated bundle config YAML.
  #
  # Default: "cogy"
  config.bundle_name = "myapp"

  # Used in the generated bundle config YAML.
  #
  # Default: "Cogy-generated commands"
  config.bundle_description = "myapp-generated commands from Cogy"

  # Can be either a string or an object that responds to `#call` and returns
  # a string.
  config.bundle_version = "0.0.1"

  # if you used a callable object, it will be evaluated each time the inventory
  # is called. This can be useful if you want the version to change dynamically
  # when it's needed.
  #
  # For example, this will change the version only when a command is
  # added or is modified (uses the 'grit' gem).
  config.bundle_version = -> {
    repo = Grit::Repo.new(Rails.root.to_s)
    repo.log("HEAD", "cogy/", max_count: 1).first.date.strftime("%y%m%d.%H%M%S")
  }

  # The path in the Relay where the cogy command executable is located at.
  config.executable_path = "/cogcmd/cogy"

  # Paths in your application where the files that define the commands live in.
  # For example the default value will search for all `*.rb` files in the `cogy/`
  # directory relative to the root of your application.
  #
  # Default: ["cogy"]
  config.command_load_paths = "cogy"
end

```

You can use the generator to quickly create a config initializer in your app:

```shell
$ bin/rails g cogy:config
```

### Helpers

It is possible to define helpers that can be used throughout commands. They
can be defined during configuration and can accept a variable number of
arguments, or no arguments at all.

Let's define a helper that fetches a `Shops` address of the user who called the
command:

```ruby
Cogy.configure do |c|
  c.helper(:shop_address) { Shop.find_by(owner: handle).address }
end
```

*(Note that custom helpers also have access to the default helpers like
`handle`, `args` etc.)*

Then we could have a command like this:

```ruby
on "shop_address", desc: "Returns the user's Shop address" do
  "@#{handle}: Your shop's address is #{shop_address}"
end
```

We can also define helpers that accept arguments:

```ruby
Cogy.configure do |c|
  c.helper(:format) { |answer| answer.titleize }
end
```

Then in our command we could call it like so:

```ruby
on "foo", desc: "Nothing special" do
  format "hello there, how are you today?"
end
```

Rails' URL helpers are also available inside the commands.

## Error template

When a command throws an error the [default error template](https://github.com/skroutz/cogy/blob/master/app/views/cogy/error.text.erb) is rendered, which
is the following:

    @<%= @user %>: Command '<%= @cmd %>' returned an error.

    ```
    <%= @exception.class %>:<%= @exception.message %>
    ```

It can be overriden in the application by creating a view in
`app/views/cogy/error.text.erb`.

## Development

Running the tests:

```shell
$ rake
```

Generating documentation:

```shell
$ rake yard
```

## Authors

* [Agis Anastasopoulos](https://github.com/agis-)
* [Mpampis Kostas](https://github.com/charkost)

## License

Cogy is licensed under MIT. See [LICENSE](LICENSE).
