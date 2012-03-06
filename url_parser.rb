require 'rubygems'
require 'cgi'
require 'pathname.rb'

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
			
			# Returns true if two urls (parsed) match
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

			# Returns @path, with '.' and '..' cleaned up
			# abs_path : if supplied, resolves @path to directory of abs_path
			def normalize_path(abs_path=nil)
				path = Pathname.new(@path)
				unless abs_path.nil?
					path = Pathname.new(abs_path).join path
				end
				path.cleanpath.to_s
			end

			alias_method :normalize, :normalize_path
			
			# Cleans up '.' and '..' in @path
			# =>  abs_path : if supplied, resolves @path to directory of abs_path
			# =>  NB: if @path starts with '/', the abs_path parameter will have no effect
			def normalize_path!(abs_path=nil)
				@path = normalize_path(abs_path)
			end

			alias_method :normalize!, :normalize_path!
					
			# Does instance lack a scheme or host
			def relative?
				path[0] == 47
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
					attr1 == attr2 or Entrity::Matcher::hashes_match?(attr1, attr2)
				elsif sym == :path
					Pathname.new(attr1).cleanpath == Pathname.new(attr2).cleanpath
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