describe Docusign::TabsUpdater do

  let(:tab_id1) { generate(:tab_id) }
  let(:tab_id2) { generate(:tab_id) }
  let(:metadata) do
    {
      textTabs: [ { tabId: tab_id1, tabLabel: "myTextTab" } ],
      checkboxTabs: [ { tabId: tab_id2, tabLabel: "myCheckboxTab" } ]
    }
  end
  let(:envelope_id) { generate(:envelope_id) }
  let(:recipient_id) { 1 }

  describe "#new" do
    before(:each) do
      allow_any_instance_of(DocusignRest::Client).to receive(:retrieve_tabs).and_return(metadata)
    end

    it "calls DocusignRest::Client#retrieve_tabs" do
      expect_any_instance_of(DocusignRest::Client).to receive(:retrieve_tabs).with(envelope_id, recipient_id)
      Docusign::TabsUpdater.new(envelope_id, recipient_id)
    end

    it "builds up the dictionary" do
      updater = Docusign::TabsUpdater.new(envelope_id, recipient_id)

      expect(updater['myTextTab'].id).to eq(tab_id1)
      expect(updater['myTextTab'].label).to eq('myTextTab')
      expect(updater['myTextTab']).to be_a(Docusign::TextTab)

      expect(updater['myCheckboxTab'].id).to eq(tab_id2)
      expect(updater['myCheckboxTab'].label).to eq('myCheckboxTab')
      expect(updater['myCheckboxTab']).to be_a(Docusign::CheckboxTab)
    end
  end
end
