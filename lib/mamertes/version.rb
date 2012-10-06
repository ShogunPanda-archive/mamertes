# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2012 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Mamertes
  # The current version of Mamertes, according to semantic versioning.
  #
  # @see http://semver.org
  module Version
    # The major version.
    MAJOR = 1

    # The minor version.
    MINOR = 1

    # The patch version.
    PATCH = 7

    # The current version number of Mamertes.
    STRING = [MAJOR, MINOR, PATCH].compact.join(".")
  end
end
