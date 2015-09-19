describe Docusign::Recipient do
  subject(:recipient) { FactoryGirl.build(:recipient) }

  describe "#new" do
    its(:id) { is_expected.to be_present }
    its(:role_name) { is_expected.to eq('Client') }
    its(:name) { is_expected.to eq('John Smith') }
    its(:email) { is_expected.to eq('john@gmail.com') }
    its(:embedded) { is_expected.to eq(true) }
  end

  describe "#to_h" do
    subject { recipient.to_h }
    its([:recipient_id]) { is_expected.to eq(recipient.id) }
    its([:role_name]) { is_expected.to eq(recipient.role_name) }
    its([:name]) { is_expected.to eq(recipient.name) }
    its([:email]) { is_expected.to eq(recipient.email) }
    its([:embedded]) { is_expected.to eq(true) }
  end
end
