# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Mamertes
  # The current version of Mamertes, according to semantic versioning.
  #
  # @see http://semver.org
  module Version
    # The major version.
    MAJOR = 2

    # The minor version.
    MINOR = 4

    # The patch version.
    PATCH = 1

    # The current version number of Mamertes.
    STRING = [MAJOR, MINOR, PATCH].compact.join(".")
  end
end
