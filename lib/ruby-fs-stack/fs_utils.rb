class FsUtils
  
  def self.querystring_from_hash(hash)
    params = hash.map do |k,v|
      k = k.to_s
      if v.is_a? Hash
        v.collect do |k2,v2|
          k2 = k2.to_s
          v2 = v2.to_s
          url_encode(v2)
          "#{k}.#{k2}=#{v2}"
        end.join('&')
      else
        v = v.to_s
        self.url_encode(v)
        k + '=' + v
      end
    end
    params.join('&')
  end
  
  private
  def self.url_encode(string)
    # Taken from http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/156044
    string.gsub!( /[^a-zA-Z0-9\-_\.!~*'()]/n ) {|x| sprintf('%%%02x', x[0]) }
  end
end