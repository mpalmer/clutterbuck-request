This provides a set of helpers to make processing Rack requests easier.


# Installation

It's a gem:

    gem install clutterbuck-request

There's also the wonders of [the Gemfile](http://bundler.io):

    gem 'clutterbuck-request'

If you're the sturdy type that likes to run from git:

    rake install

Or, if you've eschewed the convenience of Rubygems entirely, then you
presumably know what to do already.


# Usage

Load the code:

    require 'clutterbuck-request'

Include the module, and provide access to the Rack environment:

    class MyExampleApp
      include Clutterbuck::Request

      def env
        @env
      end
    end

Then you can use any of the methods in the {Clutterbuck::Request} module to
do your worst.

## The Rack environment

Since {Clutterbuck::Request} needs access to the Rack request environment in
order to do its thing, you'll need to define an instance method called
`env`, which returns the request environment.  If you're using
`clutterbuck-router`, this is already done for you, otherwise however you're
calling the app will need to be adjusted to capture the environment
somewhere (you're almost certainly already doing this) and provide it in the
`env` method.


# Contributing

Bug reports should be sent to the [Github issue
tracker](https://github.com/mpalmer/clutterbuck-request/issues), or
[e-mailed](mailto:theshed+clutterbuck@hezmatt.org).  Patches can be sent as
a Github pull request, or
[e-mailed](mailto:theshed+clutterbuck@hezmatt.org).


# Licence

Unless otherwise stated, everything in this repo is covered by the following
copyright notice:

    Copyright (C) 2015  Matt Palmer <matt@hezmatt.org>

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
