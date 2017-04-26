describe Docusign::TabsUpdater do

  let(:tab_id1) { generate(:tab_id) }
  let(:tab_id2) { generate(:tab_id) }
  let(:metadata) do
    { textTabs: [ { tabId: tab_id1, tabLabel: "myTextTab" } ],
      checkboxTabs: [ { tabId: tab_id2, tabLabel: "myCheckboxTab" } ] }
  end
  let(:envelope_id) { generate(:envelope_id) }
  let(:recipient_id) { generate(:recipient_id) }
  let(:updater) { Docusign::TabsUpdater.new(envelope_id, recipient_id) }

  before(:each) do
    allow_any_instance_of(DocusignRest::Client).to receive(:retrieve_tabs).and_return(metadata)
  end

  describe "#new" do
    it "calls DocusignRest::Client#retrieve_tabs" do
      expect_any_instance_of(DocusignRest::Client).to receive(:retrieve_tabs).with(envelope_id, recipient_id)
      updater
    end
  end

  describe "#[]" do
    context "myTextTab" do
      subject { updater['myTextTab'] }
      it { is_expected.to be_a(Docusign::TextTab) }
      its(:id) { is_expected.to eq(tab_id1) }
      its(:label) { is_expected.to eq('myTextTab') }
    end

    context "myCheckboxTab" do
      subject { updater['myCheckboxTab'] }
      it { is_expected.to be_a(Docusign::CheckboxTab) }
      its(:id) { is_expected.to eq(tab_id2) }
      its(:label) { is_expected.to eq('myCheckboxTab') }
    end
  end

  describe "#set" do

    context "'myTextTab' to 'abc'" do
      let(:label) { 'myTextTab' }
      before(:each) { updater.set(label, 'abc') }
      subject { updater[label] }

      its(:value) { is_expected.to eq('abc') }
      its(:dirty?) { is_expected.to be(true) }
    end

    context "'myCheckboxTab' to true" do
      let(:label) { 'myCheckboxTab' }
      before(:each) { updater.set(label, true) }
      subject { updater[label] }

      its(:value) { is_expected.to be(true) }
      its(:dirty?) { is_expected.to be(true) }
      its(:to_h) { is_expected.to include(selected: true) }
      its(:to_h) { is_expected.not_to include(value: true) }
    end
  end

  describe "#execute!" do

    def go!
      updater.execute!
    end

    before(:each) { allow(updater.docusign_client).to receive(:modify_tabs) }

    context "'myTextTab' set to 'abc'" do
      let(:label) { 'myTextTab' }
      before(:each) { updater.set(label, 'abc') }

      it "calls DocusignRest::Client#modify_tabs for textTabs" do
        expected_updates = {
          textTabs: [ { tabId: tab_id1, tabLabel: label, locked: true, value: "abc" } ]
        }
        expect(updater.docusign_client).to receive(:modify_tabs).with(envelope_id, recipient_id, expected_updates)
        go!
      end
    end

    context "'myCheckboxTab' set to true" do
      let(:label) { 'myCheckboxTab' }
      before(:each) { updater.set(label, true) }

      it "calls DocusignRest::Client#modify_tabs for checkboxTabs" do
        expected_updates = {
          checkboxTabs: [ { tabId: tab_id2, tabLabel: label, locked: true, selected: true } ]
        }
        expect(updater.docusign_client).to receive(:modify_tabs).with(envelope_id, recipient_id, expected_updates)
        go!
      end
    end

    context "checkboxTabs and textTabs" do
      before(:each) do
        updater.set('myCheckboxTab', true)
        updater.set('myTextTab', 'xyz')
      end

      it "updates both checkboxTabs and textTabs" do
        expected_updates = {
          textTabs: [ { tabId: tab_id1, tabLabel: 'myTextTab', locked: true, value: 'xyz', } ],
          checkboxTabs: [ { tabId: tab_id2, tabLabel: 'myCheckboxTab', locked: true, selected: true, } ],
        }
        expect(updater.docusign_client).to receive(:modify_tabs).with(envelope_id, recipient_id, expected_updates)
        go!
      end
    end

  end
end
