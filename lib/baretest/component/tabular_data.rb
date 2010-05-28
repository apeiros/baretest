require 'strscan'
require 'bigdecimal'

module BareTest

  # Recognized classes:
  #   nil                 # nil
  #   true                # true
  #   false               # false
  #   -123                # Fixnum/Bignum (decimal)
  #   0b1011              # Fixnum/Bignum (binary)
  #   0755                # Fixnum/Bignum (octal)
  #   0xff                # Fixnum/Bignum (hexadecimal)
  #   120.30              # BigDecimal
  #   1e0                 # Float
  #   "foo"               # String, no interpolation, but \t etc. work
  #   'foo'               # String, only \\ and \' are escaped
  #   /foo/               # Regexp
  #   :foo                # Symbol
  #   :"foo"              # Symbol
  #   2010-05-23          # Date
  #   2010-05-23T06:45:00 # DateTime
  class TabularData
    RNil           = /nil/
    RFalse         = /false/
    RTrue          = /true/
    RInteger       = /[+-]?\d[\d'_,]*/
    RBinaryInteger = /[+-]?0b[01][01'_,]*/
    RHexInteger    = /[+-]?0x[A-Fa-f\d][A-Fa-f\d'_,]*/
    ROctalInteger  = /[+-]?0[0-7][0-7'_,]*/
    RBigDecimal    = /#{RInteger}\.\d+/
    RFloat         = /#{RBigDecimal}e#{RInteger}/
    RSString       = /'(?:[^\\']+|\\.)*'/
    RDString       = /"(?:[^\\"]+|\\.)*"/
    RRegexp        = %r{/((?:[^\\/]+|\\.)*)/([imxnNeEsSuU]*)}
    RSymbol        = /:\w+|:#{RSString}|:#{RDString}/
    RDate          = /(\d{4})-(\d{2})-(\d{2})/
    RTimeZone      = /(Z|[A-Z]{3,4}|[+-]\d{4})/
    RTime          = /(\d{2}):(\d{2}):(\d{2})(?:RTimeZone)?/
    RDateTime      = /#{RDate}T#{RTime}/
    RSeparator     = /[^\#nft\d:'"\/+-]+|$/
    RTerminator    = /\s*(?:\#.*)?(?:\n|\r\n?|\Z)/

    RIdentifier    = /[A-Za-z_]\w*/

    DStringEscapes = {
      '\\\\' => "\\",
      "\\'"  => "'",
      '\\"'  => '"',
      '\t'   => "\t",
      '\f'   => "\f",
      '\r'   => "\r",
      '\n'   => "\n",
    }
    256.times do |i|
      DStringEscapes["\\%o" % i]    = i.chr
      DStringEscapes["\\%03o" % i]  = i.chr
      DStringEscapes["\\x%02x" % i] = i.chr
      DStringEscapes["\\x%02X" % i] = i.chr
    end

    include Enumerable

    attr_reader :variables
    attr_reader :keys
    attr_reader :length

    def initialize(data)
      data          = data.gsub(/^[ \t]*(?:\#.*)?$(?:\n|\z)|\#.*$/, '') # remove comments and empty lines
      header        = data.slice!(/\A.*(?:\r?\n|\r)/).chomp
      indent        = header[/[^@]*/]
      @variables    = header.scan(/@#{RIdentifier}/)
      @keys         = @variables.map { |variable| variable[1..-1] }
      @body         = data.gsub(/^#{Regexp.escape(indent)}/, '').split(/\n/)
      @length       = @body.length
      @data         = @body.map { |line| parse_line(line) }
    end

    def [](*idx)
      @data[*idx]
    end

    def each(&block)
      @data.each(&block)
      self
    end

    def apply(obj, idx)
      @variables.zip(@data[idx]) do |var, value|
        obj.instance_variable_set(var, value)
      end
      obj
    end

    def parse_line(line)
      #@body[idx].scan(RValue).map { |match| idx=match.find_index{|v|v}; [match.at(idx),RValueMap.at(idx)] }
      scanner = StringScanner.new(line)
      data    = []
      until scanner.eos?
        data << case
          when scanner.scan(RNil)           then nil
          when scanner.scan(RTrue)          then true
          when scanner.scan(RFalse)         then false
          when scanner.scan(RDateTime)      then
            Time.mktime(scanner[1], scanner[2], scanner[3], scanner[4], scanner[5], scanner[6])
          when scanner.scan(RDate)          then
            date = scanner[1].to_i, scanner[2].to_i, scanner[3].to_i
            Date.civil(*date)
          when scanner.scan(RTime)          then
            now = Time.now
            Time.mktime(now.year, now.month, now.day, scanner[1].to_i, scanner[2].to_i, scanner[3].to_i)
          when scanner.scan(RFloat)         then Float(scanner.matched.delete('^0-9.e-'))
          when scanner.scan(RBigDecimal)    then BigDecimal(scanner.matched.delete('^0-9.-'))
          when scanner.scan(ROctalInteger)  then Integer(scanner.matched.delete('^0-9-'))
          when scanner.scan(RHexInteger)    then Integer(scanner.matched.delete('^xX0-9A-Fa-f-'))
          when scanner.scan(RBinaryInteger) then Integer(scanner.matched.delete('^bB01-'))
          when scanner.scan(RInteger)       then scanner.matched.delete('^0-9-').to_i
          when scanner.scan(RRegexp)        then
            source = scanner[1]
            flags  = 0
            lang   = nil
            if scanner[2] then
              flags |= Regexp::IGNORECASE if scanner[2].include?('i')
              flags |= Regexp::EXTENDED if scanner[2].include?('m')
              flags |= Regexp::MULTILINE if scanner[2].include?('x')
              lang   = scanner[2].delete('^nNeEsSuU')[-1,1]
            end
            Regexp.new(source, flags, lang)
          when scanner.scan(RSymbol)        then
            case scanner.matched[1,1]
              when '"'
                scanner.matched[2..-2].gsub(/\\(?:[0-3]?\d\d?|x[A-Fa-f\d]{2}|.)/) { |m|
                  DStringEscapes[m]
                }.to_sym
              when "'"
                scanner.matched[2..-2].gsub(/\\'/, "'").gsub(/\\\\/, "\\").to_sym
              else
                scanner.matched[1..-1].to_sym
            end
          when scanner.scan(RSString)       then
            scanner.matched[1..-2].gsub(/\\'/, "'").gsub(/\\\\/, "\\")
          when scanner.scan(RDString)       then
            scanner.matched[1..-2].gsub(/\\(?:[0-3]?\d\d?|x[A-Fa-f\d]{2}|.)/) { |m| DStringEscapes[m] }
          else raise "Unrecognized pattern #{scanner.rest.inspect}"
        end
        raise "Unrecognized separator #{scanner.rest.inspect}" unless scanner.scan(RSeparator)
      end
      data
    end
  end
end
