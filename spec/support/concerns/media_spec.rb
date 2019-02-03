require 'rails_helper'

RSpec.shared_examples_for "media" do
  let(:model) { described_class } # the class that includes the concern
  before do
    @family = FactoryBot.create(:family)
    @member = FactoryBot.create(:family_member, family_id: @family.id).member
    if described_class == Comment
      parent = FactoryBot.create(:post)
      @media_subject = FactoryBot.build(:comment, commentable_id: parent.id, commentable_type: "Post", member_id: parent.member_id)
    elsif described_class == Recipe
      @media_subject = FactoryBot.build(:"#{described_class.to_s.downcase}", member_id: @member.id)
    else
      @media_subject = FactoryBot.build(:"#{described_class.to_s.downcase}", member_id: @member.id, family_id: @family.id)
    end
  end
  context "Basic Model Tests for #{described_class}'s media attachments" do
    describe ':: Attaching' do
      it 'saves the image' do
        @media_subject.save!        
        expect(@media_subject.media).to_not be_attached
        @media_subject.media.attach(io: File.open(Rails.root.to_s + "/spec/fixtures/images/img.jpg"), filename: "img.jpg", content_type: "image/jpg")
        expect(@media_subject.media.instance_of?(ActiveStorage::Attached::One)).to be_truthy
        expect(@media_subject.media).to be_attached
      end
      it "the attachment record should match #{described_class.to_s.downcase}'s record'" do
        @media_subject.save!        
        @media_subject.media.attach(io: File.open(Rails.root.to_s + "/spec/fixtures/images/img.jpg"), filename: "img.jpg", content_type: "image/jpg")
        expect(@media_subject.media.attachment.record_id).to eq(@media_subject.id)
        expect(@media_subject.media.attachment.record_type).to eq(@media_subject.class.to_s)
        expect(@media_subject.media.blob.instance_of?(ActiveStorage::Blob)).to be_truthy
      end
    end
  end

end # Test End
