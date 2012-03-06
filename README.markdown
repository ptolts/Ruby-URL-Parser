Usage
=====

The Ruby core class URI doesn't handle relative urls, so I created this module.

Parse a url
-----

	text = "http://www.watchseries-online.com:80/bar/foo.html#qux?s=bob%27s+burgers&search={"
	url = Entrity::URL::parse(text)
	url.scheme
	=> 'http'
	url.host
	=> 'www.watchseries-online.com'
	url.port
	=> '80'
	url.path
	=> '/bar/foo.html'
	url.fragment
	=> 'qux'
	url.data
	=> 's=bob%27s+burgers&search='
	
Compare two urls
-----

###Nil values

	url1 = 'http://www.foo.com/bar/baz/qux.html'
	url2 = '/bar/baz/qux.html?gravy=train'
	Entrity::URL::urls_identical?(url1, url2)
	=> true
	Entrity::URL::urls_identical?(url1, url2, false)
	=> false

Obsesrve that by default, the two strings match, even though one has no host and the other has no query data. Nil attribute values are treated as matches. Turn off default by setting ignore_nil to false in the params.

The foregoing compares Strings. To compare already-parsed urls, use the method Entrity::URL::Parsed::urls_identical?.


###'.' and '..' in path
	
	url1 = 'http://www.foo.com/bar/baz/qux.html'
	url2 = 'http://www.foo.com/bar/../bar/baz/qux.html'
	Entrity::URL::urls_identical?( url1, url2 )
	=> true

Normalized versions of the path are used when comparing urls.

###Relative URLs

	url1 = 'http://www.foo.com/bar/baz/qux.html'
	url2 = 'qux.html'
	Entrity::URL::Parsed.urls_identical?(url1, url2)
	=> true
	Entrity::URL::Parsed.urls_identical?(url1, url2, true, false)
	=> false

By default, if one url is relative and the other is not, then the relative url will attempt to normalize against the absolute url (i.e. as though it were appearing in a hyperlink in the bottom-level directory holding the other url). Turn off this behaviour by setting normalize to false in the params.

Dependencies
-----
rubygems 	// for sake of cgi
cgi			// to parse query string into a hash
pathname.rb	// to normalize paths containing '.' or '..'

Notes
-----
Whereas I find the Ruby core class URI is not too useful for parsing URLs, I put this together.
The fields @scheme, @host, @port, @path, @fragment, @data are all mutable.