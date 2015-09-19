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

  describe ".merge" do

    let(:merged) { Docusign::Recipient.merge(recipients) }

    context "single recipient" do
      let(:recipients) do
        [ FactoryGirl.build(:recipient, id: 1, tabs: { firstname: 'John' } ),
          FactoryGirl.build(:recipient, id: 1, tabs: { lastname: 'Smith' } ) ]
      end

      subject { merged.first }

      it("should have one recipient") { expect(merged).to have(1).items }
      its(:tabs) { is_expected.to eq({ firstname: 'John', lastname: 'Smith' }) }
    end

    context "multiple recipients" do
      let(:recipients) do
        [
          FactoryGirl.build(:recipient, :cco, id: 2),
          FactoryGirl.build(:recipient, id: 1, tabs: { lastname: 'Smith' } ),
          FactoryGirl.build(:recipient, id: 1, tabs: { firstname: 'John' } ),
        ]
      end

      it("should have two merged recipients") { expect(merged).to have(2).items }

      describe "merged[0]" do
        subject { merged[0] }
        its(:id) { is_expected.to eq(1) }
        its(:role_name) { is_expected.to eq('Client') }
        its(:email) { is_expected.to eq('john@gmail.com') }
        its(:tabs) { is_expected.to eq({ firstname: 'John', lastname: 'Smith'}) }
      end

      describe "merged[1]" do
        subject { merged[1] }
        its(:id) { is_expected.to eq(2) }
        its(:role_name) { is_expected.to eq('Chief Compliance Officer') }
        its(:email) { is_expected.to eq('dave@wealthsimple.com') }
        its(:tabs) { is_expected.to be(nil) }
      end
    end
  end

end
