#--
# Copyright 2009-2010 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



suite "IRB", :use => :basic_verifications do
  setup do
    @a = 1
    @b = 0
  end

  suite "Error in setup" do
    setup do
      @c = @a+b # should be @b
    end

    exercise "1*2" do
      @a*@b
    end

    verify "won't happen" do
      returns 0
    end
  end

  suite "Error in exercise" do
    exercise "We fail" do
      @a/@b # should be @a*@b
    end

    verify "won't happen" do
      returns 0
    end
  end

  suite "Error in verify" do
    exercise "We fail" do
      @a*@b
    end

    verify "won't happen" do
      retruns 0 # typo, should be returns 0
    end
  end

  suite "Error in teardown" do
    exercise "We fail" do
      @a*@b
    end

    verify "won't happen" do
      returns 0
    end

    teardown do
      raise "no wonder this errors"
    end
  end
end
