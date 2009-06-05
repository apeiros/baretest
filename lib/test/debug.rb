#--
# Copyright 2009 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++



module Test
	class Suite
		def to_s
			sprintf "%s %s", self.class, @description
		end

		def inspect
			sprintf "#<%s:%08x %p>", self.class, object_id>>1, @description
		end
	end

	class Assertion
		def to_s
			sprintf "%s %s", self.class, @description
		end

		def inspect
			sprintf "#<%s:%08x @suite=%p %p>", self.class, object_id>>1, @suite, @description
		end
	end
end
