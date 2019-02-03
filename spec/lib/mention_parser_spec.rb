require "rails_helper"
require "mention_parser"

RSpec.describe MentionParser do
  describe "#members" do
    it "returns members who are mentioned in the body" do
      member1 = FactoryBot.create(:member)
      member2 = FactoryBot.create(:member)
      member3 = FactoryBot.create(:member)
      member4 = FactoryBot.create(:member)
      member5 = FactoryBot.create(:member)

      body = """
      @#{member1.name} #{member1.surname}
      some text
      @#{member2.name} #{member2.surname}
      some more text
      some more text
      @#{member3.name} #{member3.surname}
      @#{member4.name} #{member4.surname}
      """

      parser = MentionParser.new(body)
      expect(parser.members).to include(member1, member2, member3, member4)
    end
  end
end