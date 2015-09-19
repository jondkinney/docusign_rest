describe Docusign::Envelope do

  subject(:envelope) { FactoryGirl.build(:envelope, :with_recipients, :with_template_ids) }
  let(:docusign_client) { envelope.docusign_client }

  describe "#new" do
    its(:id) { is_expected.to be_nil }
    its(:template_ids) { is_expected.to have_exactly(2).items }
    its(:recipients) { is_expected.to have_exactly(2).items }
    its(:docusign_client) { is_expected.to be_a(DocusignRest::Client) }
  end

  describe "#create_draft_envelope!" do
    let(:envelope_id) { FactoryGirl.generate(:envelope_id) }
    before(:each) do
      allow(docusign_client).to receive(:create_envelope_from_composite_template).and_return({'envelopeId' => envelope_id})
    end

    def go!
      envelope.create_draft_envelope!
    end

    it "calls DocusignRest::Client#create_envelope_from_composite_template" do
      expect(docusign_client).to receive(:create_envelope_from_composite_template).once
      go!
    end

    it "constructs the correct request" do
      expected_request = {
        status: 'created',
        body: 'Please sign these forms',
        subject: 'Please sign these forms',
        server_template_ids: envelope.template_ids,
        signers: envelope.recipients.map(&:to_h)
      }
      expect(docusign_client).to receive(:create_envelope_from_composite_template).with(expected_request)
      go!
    end

    it "updates id" do
      expect { go! }.to change{ envelope.id }.from(nil).to(envelope_id)
    end
  end

  describe "#update_tabs!" do
    subject(:envelope) do
      FactoryGirl.build(:envelope, :with_recipients, :with_template_ids, :with_envelope_id)
    end
    let(:recipients) { envelope.recipients }
    let(:envelope_id) { envelope.id }
    let!(:recipient_id1) { envelope.recipients[0].id }
    let!(:recipient_id2) { envelope.recipients[1].id }
    let!(:tab_id1) { FactoryGirl.generate(:tab_id) }
    let!(:tab_id2) { FactoryGirl.generate(:tab_id) }
    let!(:tab_id3) { FactoryGirl.generate(:tab_id) }

    def go!
      envelope.update_tabs!
    end

    it "calls DocusignRest::Client#retrieve_tabs for each recipient" do
      expect(docusign_client).to receive(:retrieve_tabs).with(envelope_id, recipient_id1)
      expect(docusign_client).to receive(:retrieve_tabs).with(envelope_id, recipient_id2)
      go!
    end


    it "calls DocusignRest::Client#modify_tabs for only recipients with tabs" do
      allow(docusign_client).to receive(:retrieve_tabs).with(envelope_id, recipient_id1).and_return({
        textTabs: [ { tabLabel: 'given_name', tabId: tab_id1 },
                    { tabLabel: 'surname', tabId: tab_id2 },
                    { tabLabel: 'citizenship', tabId: tab_id3 } ] })
      allow(docusign_client).to receive(:retrieve_tabs).with(envelope_id, recipient_id2).and_return({})

      expect(docusign_client).to receive(:modify_tabs).with(envelope_id, recipient_id1, {
        textTabs: [
          { tabId: tab_id1, value: 'John', locked: true },
          { tabId: tab_id2, value: 'Smith', locked: true },
          { tabId: tab_id3, value: 'Canadian', locked: true },
        ]
      })
      go!
    end
  end

  describe "#send_envelope!" do
    before(:each) do
      allow(envelope).to receive(:create_draft_envelope!)
      allow(envelope).to receive(:update_tabs!)
      allow(docusign_client).to receive(:send_envelope)
    end

    def go!
      envelope.send_envelope!
    end

    it "calls #create_draft_envelope!" do
      expect(envelope).to receive(:create_draft_envelope!)
      go!
    end

    it "calls #update_tabs!" do
      expect(envelope).to receive(:update_tabs!)
      go!
    end

    it "calls DocusignRest::Client#send_envelope" do
      expect(docusign_client).to receive(:send_envelope).with(envelope.id)
      go!
    end
  end

end
