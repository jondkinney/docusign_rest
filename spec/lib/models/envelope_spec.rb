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

    let(:updater) { double }

    it "calls DocusignRest::Client#retrieve_tabs for each recipient" do
      allow(Docusign::TabsUpdater).to receive(:new).and_return(updater)
      allow(updater).to receive(:execute!)
      expect(updater).to receive(:set).with(:given_name, 'John')
      expect(updater).to receive(:set).with(:surname, 'Smith')
      expect(updater).to receive(:set).with(:citizenship, 'Canadian')
      expect(updater).to receive(:execute!).twice
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

  describe "#recipient_view" do

    let(:url) { 'myUrl'}
    let(:response) { {'url' => url } }
    let(:recipient) { envelope.recipients.first }
    let(:recipient_id) { recipient.id }
    let(:envelope) do
      FactoryGirl.build(:envelope, :with_recipients, :with_template_ids, :with_envelope_id)
    end

    before(:each) do
      allow(docusign_client).to receive(:get_recipient_view).and_return(response)
    end

    context "valid recipient id" do
      it "calls DocusignRest::Client#get_recipient_view" do
        expect(docusign_client).to receive(:get_recipient_view).with(envelope_id: envelope.id, name: recipient.name, email: recipient.email, return_url: 'http://www.google.com')
        expect(envelope.recipient_view(recipient_id)).to eq(url)
      end
    end

    context "invalid recipient_id" do
      before(:each) do
        allow(docusign_client).to receive(:get_recipient_view).and_return({})
      end
      it "returns nil" do
        expect(envelope.recipient_view(999)).to be(nil)
      end
    end

    context "with return_url" do
      let(:return_url) { 'my return url' }
      it "calls DocusignRest::Client#get_recipient_view with return_url" do
        expect(docusign_client).to receive(:get_recipient_view).with(envelope_id: envelope.id, name: recipient.name, email: recipient.email, return_url: return_url)
        expect(envelope.recipient_view(recipient_id, return_url)).to eq(url)
      end
    end
  end
end
