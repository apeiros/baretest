#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test
	class Suite
		def inspect
			sprintf "#<%s:%08x %p>", self.class, object_id>>1, @name
		end
	end

	class Assertion
		def inspect
			sprintf "#<%s:%08x @suite=%p %p>", self.class, object_id>>1, @suite, @message
		end
	end
end
