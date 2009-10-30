# Kernel#with_warnings_suppressed - Supresses warnings in a given block.
# Require this file to use it or run it directly to perform a self-test.
# 
# Author:: Rob Pitt
# Copyright:: Copyright (c) 2008 Rob Pitt
# License:: Free to use and modify so long as credit to previous author(s) is left in place.
#

module Kernel
  # Suppresses warnings within a given block.
  def with_warnings_suppressed
    saved_verbosity = $-v
    $-v = nil
    yield
  ensure
    $-v = saved_verbosity
  end
end
