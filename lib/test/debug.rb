module Test
	class Suite
		def inspect
			sprintf "#<%s:%08x %s>", self.class, object_id>>1, @name
		end
	end

	class Assertion
		def inspect
			sprintf "#<%s:%08x %s>", self.class, object_id>>1, @message
		end
	end
end
