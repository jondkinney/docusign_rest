describe Docusign::Recipient do
  subject(:recipient) { FactoryGirl.build(:recipient, :with_tabs) }

  describe "#new" do
    its(:id) { is_expected.to be_present }
    its(:role_name) { is_expected.to eq('Client') }
    its(:name) { is_expected.to eq('John Smith') }
    its(:email) { is_expected.to eq('john@gmail.com') }
    its(:embedded) { is_expected.to eq(false) }
  end

  describe "#to_h" do
    subject { recipient.to_h }
    its([:recipientId]) { is_expected.to eq(recipient.id) }
    its([:roleName]) { is_expected.to eq(recipient.role_name) }
    its([:name]) { is_expected.to eq(recipient.name) }
    its([:email]) { is_expected.to eq(recipient.email) }
    its([:clientUserId]) { is_expected.to eq(recipient.email) }
    its([:embedded]) { is_expected.to eq(false) }
    its([:tabs]) { is_expected.to eq(
      { textTabs: [
          {tabLabel: :naaf_given_name, locked: true, value: 'Jack'},
          {tabLabel: :naaf_surname, locked: true, value: 'Smith'},
          {tabLabel: :naaf_dob_year, locked: true, value: '1984'},
          {tabLabel: :naaf_dob_month, locked: true, value: '05'},
          {tabLabel: :naaf_address, locked: true, value: '' }
        ],
        checkboxTabs: [
          {tabLabel: :naaf_us_person_yes, locked: true, selected: true},
          {tabLabel: :naaf_us_person_no, locked: true, selected: false}
        ]
      }
    )}
  end

end
