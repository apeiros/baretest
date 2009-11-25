#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



BareTest.suite "Failure" do
  setup do
    @a = 1
    @b = 2
  end

  assert "This one should fail and thus drop you into irb" do
    c = 3
    d = 4
    @a == d
  end

  assert "This one should error and thus drop you into irb" do
    c = 3
    d = 4
    raise "error!"
  end
end
