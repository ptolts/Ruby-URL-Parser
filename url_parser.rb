require 'rubygems'
require 'cgi'

class Entrity
	
	module URL
	
		# Returns an instance of Parsed
		def self.parse(url)
			Parsed.new(url)
		end
		
		# Returns true if 2 url Strings match. (Will parse strings and compare attributes.)
		# ignore_nil == true: a nil value for an attribute in either url counts as a match
		# Attempts to normalize any relative urls against absolute urls
		def self.urls_identical?(url1, url2, ignore_nil=true, normalize=true)
			p1 = parse(url1)
			p2 = parse(url2)
			Parsed.urls_identical?(p1, p2)
		end
	
		class Parsed
			@@attrs = [:scheme, :host, :port, :path, :frag, :data]
			attr_accessor *@@attrs
			
			def self.attrs; @@attrs; end
			
			# Returns an instance of Parser
			def self.parse(url)
				self.new(url)
			end
			
			# Returns true if two urls (not parsed) match
			# - ignore_nil = [boolean] - a nil value for an attribute in either url counts as a match
			# - normalize = [boolean] - if one path is relative but not both, then the relative path will be normalized as though it were relative to the absolute path
			def self.urls_identical?(url1, url2, ignore_nil=true, normalize=true)
				if normalize and (url1.relative? ^ url2.relative?)
					url1.relative? ? url2.normalize_path!(url1) : url1.normalize_path!(url2)
				end
				@@attrs.each do |attr|
					return false unless attr_match?(attr, url1, url2, ignore_nil)
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
				[*[to_s + '{'] + attrs + ['}']].join(joiner)
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
			
			# Called by self.urls_identical?
			# Returns true if two parsed urls have identical strings for given attribute
			# - ignore_nil = [boolean] - a nil value for the attribute in either url counts as a match
			def self.attr_match?(sym, parsed_url1, parsed_url2, ignore_nil)
				attr1 = parsed_url1.send sym
				attr2 = parsed_url2.send sym
				# Create Hashes if attribute is query data
				if attr1 == attr2
					true
				elsif ignore_nil and (attr1.nil? or attr2.nil?)
					true
				elsif sym == :data
					attr1 = CGI::parse attr1
					attr2 = CGI::parse attr2
					if attr1 == attr2
						true
					else
						Entrity::Matcher::hashes_match?(attr1, attr2)
					end
				else
					false
				end
			end
			
		end
		
	end
	
	module Matcher
		
		# Returns true if hashes have all the k-v pairs (w/ arrays matching regardless of order)
		def self.hashes_match?(h1, h2)
			return false if h1.length != h2.length
			h1.each_key do |key|
				return false if !elements_match?(h1[key], h2[key])
			end
			true
		end

		# Returns true if arrays have all the same elements, regardless of order
		def self.arrays_match?(a1, a2)
			return false if a1.length != a2.length
			a1.each do |e1|
				return false if a2.all? { |e2| !elements_match?(e1, e2) }
			end
			true
		end

		# Returns true if elements match (kind of)
		def self.elements_match?(e1, e2)
			return false if e1.class != e2.class
			return hashes_match?(e1, e2) if e1.is_a?(Hash)
			return arrays_match?(e1, e2) if e1.is_a?(Array)
			return e1 == e2
		end

	end	
	
end