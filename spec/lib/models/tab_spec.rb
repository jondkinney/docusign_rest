describe Docusign::Tab do

  describe ".class_for" do
    subject{ described_class.class_for(key) }

    context ":checkboxTabs" do
      let(:key) { :checkboxTabs }
      it { is_expected.to eq(Docusign::CheckboxTab) }
    end

    context ":textTabs" do
      let(:key) { :textTabs }
      it { is_expected.to eq(Docusign::TextTab) }
    end

    context "'checkboxTabs'" do
      let(:key) { 'checkboxTabs' }
      it { is_expected.to eq(Docusign::CheckboxTab)}
    end

    context "'textTabs'" do
      let(:key) { 'textTabs' }
      it { is_expected.to eq(Docusign::TextTab)}
    end
  end

  describe "#value=" do
    subject(:tab) { described_class.new }

    its(:dirty?) { is_expected.to be(false) }
    its(:value) { is_expected.to be_nil }
    it "makes dirty? true" do
      expect{ tab.value = 'abc' }.to change{ tab.dirty? }.to(true)
    end
  end

  describe "#to_h" do
    let(:tab) { described_class.new(id: 'abc', label: 'myLabel') }
    subject { tab.to_h }
    its(:to_h) { is_expected.to eq(tabId: 'abc', tabLabel: 'myLabel', locked: true) }
  end

  describe ".collection_name" do
    it "raises error" do
      expect{ described_class.collection_name }.to raise_error
    end
  end

end
