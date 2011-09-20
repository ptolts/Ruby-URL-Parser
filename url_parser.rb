class Entrity
	class URL
		class Parser
			
			@@attrs = [:scheme, :host, :port, :path, :data]
			attr_accessor *@@attrs
			
			# Returns an instance of Parser
			def self.parse(url)
				parser = Parser.new
				parser.parse(url)
			end
			
			# Called by self.urls_identical?
			# Returns true if two parsed urls have identical strings for given attribute
			# ignore_nil == true: a nil value for the attribute in either url counts as a match
			def self._attr_match?(sym, parsed_url1, parsed_url2, ignore_nil)
				attr1 = parsed_url1.send sym
				attr2 = parsed_url2.send sym
				if attr1 == attr2
					true
				elsif ignore_nil
					attr1.nil? or attr2.nil?
				else
					false
				end
			end
			
			# Returns true if two urls (not parsed) match
			# ignore_nil == true: a nil value for an attribute in either url counts as a match
			# Will never say a fragment is identical to a non-fragment
			def self.urls_identical?(url1, url2, ignore_nil=true)
				p1 = parse(url1)
				p2 = parse(url2)
				@@attrs.each do |attr|
					return false unless _attr_match?(attr, p1, p2, ignore_nil)
				end
				true
			end
			
			# Sets @scheme, @host, @port, @path, @data
			def parse(url)
				match = _match(url)
				@scheme = match[2]
				@host = match[3]
				@port = match[4]
				@path = match[5]
				@data = match[6]
				self
			end
			
			# Does path begin with '/' (ASCII:47)
			def fragment?
				path[0] != 47
			end
			
			# Does instance lack a scheme or host
			def relative?
				scheme.nil? or host.nil?
			end
			
			# Does instance have a scheme and host
			def absolute?
				!relative?
			end
			
			# Return string url
			def to_s
				scheme = "#{@scheme}://" unless @scheme.nil?
				host = "#{@host}" unless @host.nil?
				port = ":#{@port}" unless @port.nil?
				path = "#{@path}" unless @path.nil?
				data = "?#{@data}" unless @data.nil?
				"#{scheme}#{host}#{port}#{path}#{data}"
			end
			
			# Called by parse()
			# Returns MatchData
			def _match(url)
				scheme	= /([a-z]*):\/\//i
				host 		= /([\w\-.]*)/i
				port 		= /:([0-9]+)/
				path 		= /([^?]*)/
				data 		= /\?(.*)/
				regex 	=  /^(#{scheme}#{host})?#{port}?#{path}#{data}?/
				regex.match(url.to_s)
			end	
			
			def inspect(lf=true)
				joiner = lf ? "\n" : " "
				attrs = @@attrs.collect{|x| send x}
				puts [*[to_s + '{'] + attrs + ['}']].join(joiner)
			end

		end
	end
end