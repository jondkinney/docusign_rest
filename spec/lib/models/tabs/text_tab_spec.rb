describe Docusign::TextTab do

  let(:tab) { FactoryGirl.build(:text_tab, value: value) }
  let(:value) { 'myValue' }
  let(:label) { tab.label }

  describe "#to_h" do
    subject { tab.to_h }

    context "when value is a string" do
      let(:value) { 'myValue' }
      it { is_expected.to eq(tabLabel: label, locked: true, value: value ) }
    end

    context "when value is not a stirng" do
      let(:value) { 'myValue' }
      it { is_expected.to eq(tabLabel: label, locked: true, value: value.to_s ) }
    end

    context "when value is nil" do
      let(:value) { nil }
      it { is_expected.to eq(tabLabel: label, locked: true, value: '') }
    end
  end

  describe "#collection_name" do
    subject { tab.collection_name }
    it { is_expected.to eq(:textTabs) }
  end
end
