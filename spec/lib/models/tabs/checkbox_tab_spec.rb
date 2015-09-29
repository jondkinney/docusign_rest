describe Docusign::CheckboxTab do

  let(:tab) { FactoryGirl.build(:checkbox_tab, value: value) }
  let(:value) { true }
  let(:label) { tab.label }

  describe "#to_h" do
    subject { tab.to_h }

    context "when value is a boolean" do
      it { is_expected.to eq(tabLabel: label, locked: true, selected: value) }
    end

    context "when value is nil" do
      let(:value) { nil }
      it { is_expected.to eq(tabLabel: label, locked: true) }
    end
  end

  describe "#collection_name" do
    subject { tab.collection_name }
    it { is_expected.to eq(:checkboxTabs) }
  end
end
