class Entrity
	class URL
		class Parsed
			
			@@attrs = [:scheme, :host, :port, :path, :frag, :data]
			attr_accessor *@@attrs
			
			# Returns an instance of Parser
			def self.parse(url)
				parser = Parsed.new(url)
			end
			
			# Called by self.urls_identical?
			# Returns true if two parsed urls have identical strings for given attribute
			# - ignore_nil = [boolean] - a nil value for the attribute in either url counts as a match
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
			# - ignore_nil = [boolean] - a nil value for an attribute in either url counts as a match
			# - normalize = [boolean] - if one path is relative but not both, then the relative path will be normalized as though it were relative to the absolute path
			def self.urls_identical?(url1, url2, ignore_nil=true, normalize=true)
				p1 = parse(url1)
				p2 = parse(url2)
				if normalize and (p1.relative? ^ p2.relative?)
					p1.relative? ?	p2.normalize_path!(p1) : p1.normalize_path!(p2)
				end
				@@attrs.each do |attr|
					return false unless _attr_match?(attr, p1, p2, ignore_nil, normalize)
				end
				true
			end
			
			# Normalizes the path of this instance against another url
			# - abs_url [String or instance of this class]
			def normalize_path!(abs_url=nil)
				# Either this must be from_root? or a parsed_abs_url must be provided
				if abs_url.nil? and !from_root?
					raise "Absolute url must be provided in args because this path does not start at root: #{@path}" 
				elsif !from_root?
				# Concatentate @path on the end of abs_url's path
					abs_url = Parsed.parse(abs_url) unless abs_url.is_a?(Parsed) # Ensure abs_url is parsed
					abs_path = abs_url.path # Get path
					raise "Absolute url does not have absolute path: {#{abs_path}}" unless abs_url.from_root?
					abs_path = abs_path.slice(1..-1)
					abs_path = File.split(abs_path)[0] unless File.extname(abs_path).empty? # Drop last element of path if it has an extension (i.e. looks like file)
					abs_path += "/#{@path}" # concatenate abs_path and @path
				else
					abs_path = @path
				end
				# Split @path into array of dirs; remove all dirs preceding '..'; remove all '..', ''
				dirs = abs_path.split('/')
				indices_to_delete = []
				dirs.each_index do |i|
					if dirs[i] == '..'
						raise "Bad absolute url. Path begins with '..': {#{abs_path}}" if i == 0
						indices_to_delete.push(i-1, i)
					elsif dirs[i].empty?
						indices_to_delete.push(i)
					end
				end
				indices_to_delete.each_index do |i|
					dirs.delete_at(indices_to_delete[i] - i)
				end
				# Set path to normalized url
				@path = '/' + dirs.join('/')
			end
					
			# Does instance lack a scheme or host
			def relative?
				scheme.nil? or host.nil?
			end
			
			# Does instance have a scheme and host
			def absolute?
				!relative?
			end
			
			# Does path begin with '/' (ASCII:47)
			def from_root?
				path[0] == 47
			end
			
			# Return string url
			def to_s
				scheme = "#{@scheme}://" unless @scheme.nil?
				host = "#{@host}" unless @host.nil?
				port = ":#{@port}" unless @port.nil?
				path = "#{@path}" unless @path.nil?
				frag = "##{@frag}" unless @frag.nil?
				data = "?#{@data}" unless @data.nil?
				"#{scheme}#{host}#{port}#{path}#{frag}#{data}"
			end
			
			def inspect(lf=true)
				joiner = lf ? "\n" : " "
				attrs = @@attrs.collect{|x| send x}
				puts [*[to_s + '{'] + attrs + ['}']].join(joiner)
			end

			# Sets @scheme, @host, @port, @path, @data
			def initialize(url)
				m = match(url)
				@scheme = m[2]
				@host = m[3]
				@port = m[4]
				@path = m[5]
				@frag = m[6]
				@data = m[7]
			end
			
			private
			
			# Called by parse()
			# Returns MatchData
			def match(url)
				scheme	= /([a-z]*):\/\//i
				host 		= /([\w\-.]*)/i
				port 		= /:([0-9]+)/
				path 		= /([^?#]*)/
				data 		= /\?(.*)/
				frag		= /#([^?]*)/
				regex 	=  /^(#{scheme}#{host})?#{port}?#{path}#{frag}?#{data}?/
				regex.match(url.to_s)
			end	
			
		end
	end
end