# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2012 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "rubygems"
require "optparse"
require "prettyprint"
require "bovem"

Lazier.load!(:object)

require "mamertes/version" if !defined?(Mamertes::Version)
require "mamertes/command"
require "mamertes/option"
require "mamertes/application"
require "mamertes/parser"