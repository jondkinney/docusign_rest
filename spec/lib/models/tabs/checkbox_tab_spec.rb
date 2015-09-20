describe Docusign::CheckboxTab do

  let(:tab) { FactoryGirl.build(:checkbox_tab, value: true) }

  describe "#to_h" do
    subject { tab.to_h }
    it { is_expected.to eq(tabId: tab.id, tabLabel: tab.label, locked: true, selected: tab.value) }
  end

  describe ".collection_name" do
    subject { described_class.collection_name }
    it { is_expected.to eq(:checkboxTabs) }
  end
end
