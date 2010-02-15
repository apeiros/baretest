$LOAD_PATH.unshift(File.expand_path("#{__FILE__}/../../lib"))
require 'baretest'

BareTest do
  require_baretest "0.4"
  require_ruby     "1.8.6"
  use              :support
end
