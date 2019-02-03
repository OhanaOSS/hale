class MentionParser
  def initialize(body)
    @body = body
  end

  def members
    @members = []

    # Parses the body looking for names and returns an array of names like:
    # [["@Frances Bergnaum"], ["@Dakota Rath"], ["@Sven Cummings"], ["@Jaida Dach"]]
    # It then maps the names removing the @sign and splitting the last name 
    # causing the find_by to search by name and surname via name.first and name.last.
    # 
    # Regex Match Examples
    # @John Doe         [Match]
    # @First Last-Last  [Match]
    # @Alex. Stophel
    # @Lassiter Gregg.  [Match]

    names = @body.scan(/(@[A-z]+ [A-z]+[-]+[A-z]+|@[A-z]+ [A-z]+)/)

    names.map do |name|
      name = name[0].slice(1..-1).split(" ")
      @members << Member.find_by(name: name.first, surname: name.last)
    end
    return @members

  end
end