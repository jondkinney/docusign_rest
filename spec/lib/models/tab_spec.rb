describe Docusign::Tab do

  describe "#value=" do
    subject(:tab) { Docusign::Tab.new(label: 'myLabel') }

    its(:dirty?) { is_expected.to be(false) }
    its(:value) { is_expected.to be_nil }
    it "makes dirty? true" do
      expect{ tab.value = 'abc' }.to change{ tab.dirty? }.to(true)
    end
  end

  describe "#to_h" do
    let(:value) { 'myValue' }
    subject { tab.to_h }

    context "with id" do
      let(:tab) { Docusign::Tab.new(label: 'myLabel', id: 'abc', value: value) }
      it { is_expected.to eq(tabLabel: 'myLabel', tabId: 'abc', locked: true) }
    end

    context "without id" do
      let(:tab) { Docusign::Tab.new(label: 'myLabel', value: value) }
      it { is_expected.to eq(tabLabel: 'myLabel', locked: true) }
    end
  end

  describe "#collection_name" do
    let(:label) { 'myLabel' }
    context Docusign::Tab do
      it("equals :tabs") { expect(Docusign::Tab.new(label: label).collection_name).to eq(:tabs) }
    end
    context Docusign::TextTab do
      it("equals :textTabs") { expect(Docusign::TextTab.new(label: label).collection_name).to eq(:textTabs) }
    end
    context Docusign::CheckboxTab do
      it("equals :checkboxTabs") { expect(Docusign::CheckboxTab.new(label: label).collection_name).to eq(:checkboxTabs) }
    end
  end


  describe ".group" do
    let(:text_tab1) { FactoryGirl.build(:text_tab, label: 'x') }
    let(:text_tab2) { FactoryGirl.build(:text_tab, label: 'y') }
    let(:checkbox_tab1) { FactoryGirl.build(:checkbox_tab, label: 'a') }
    let(:checkbox_tab2) { FactoryGirl.build(:checkbox_tab, label: 'b') }
    let(:tab) { FactoryGirl.build(:tab) }
    let(:tabs) { [text_tab1, text_tab2, checkbox_tab1, checkbox_tab2] }

    subject { Docusign::Tab.group(tabs) }

    its(:keys) { is_expected.to eq([:textTabs, :checkboxTabs]) }
    its([:textTabs]) { is_expected.to eq([text_tab1, text_tab2]) }
    its([:checkboxTabs]) { is_expected.to eq([checkbox_tab1, checkbox_tab2]) }

    context "tabs is nil" do
      let(:tabs) { nil }
      it { is_expected.to be(nil) }
    end

    context "tabs is empty" do
      let(:tabs) { {} }
      it { is_expected.to be(nil) }
    end

    context "tabs contains non-Tab subclass elements" do
      let(:tabs) { [text_tab1, checkbox_tab1, "hello", tab] }
      its(:keys) { is_expected.to eq([:textTabs, :checkboxTabs]) }
      its([:textTabs]) { is_expected.to eq([text_tab1]) }
      its([:checkboxTabs]) { is_expected.to eq([checkbox_tab1]) }
    end
  end
end
