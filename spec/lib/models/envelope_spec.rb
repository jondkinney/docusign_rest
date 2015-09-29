describe Docusign::Envelope do

  subject(:envelope) { FactoryGirl.build(:envelope) }
  let(:composite_templates) { FactoryGirl.build_list(:composite_template, 2) }
  let(:email) { { subject: 'my subject', body: 'my body' } }

  describe "#new" do
    subject { Docusign::Envelope.new(composite_templates: composite_templates, email: email) }
    its(:id) { is_expected.to be_nil }
    its(:docusign_client) { is_expected.to be_a(DocusignRest::Client) }

    context "with composite_templates and email" do
      its(:composite_templates) { is_expected.to eq(composite_templates) }
      its(:email) { is_expected.to eq(email) }
    end

    context "without email" do
      let(:email) { nil }
      its(:composite_templates) { is_expected.to eq(composite_templates) }
      its(:email) { is_expected.to eq(nil) }
    end

    context "without composite_template" do
      let(:composite_templates) { nil }
      its(:composite_templates) { is_expected.to eq(nil) }
      its(:email) { is_expected.to eq(email) }
    end
  end

  describe "#to_h" do
    let(:envelope) { FactoryGirl.build(:envelope, :with_composite_templates, :with_email) }
    subject { envelope.to_h }

    its([:status]) { is_expected.to eq('sent') }
    its([:emailSubject]) { is_expected.to eq('email subject') }
    its([:compositeTemplates]) { is_expected.to be_present }


    context "without composite templates" do
      let(:envelope) { FactoryGirl.build(:envelope, :with_email) }
      its([:status]) { is_expected.to eq('sent') }
      its([:emailSubject]) { is_expected.to eq('email subject') }
      its([:compositeTemplates]) { is_expected.not_to be_present }
    end
  end

  describe "#create_envelope" do
    let(:docusign_client) { envelope.docusign_client }
    let(:envelope_id) { FactoryGirl.generate(:envelope_id) }
    it "should call Docusign::Client#create_envelope" do
      expect(docusign_client).to receive(:create_envelope).and_return(envelopeId: envelope_id)
      expect(envelope.create_envelope!).to eq(envelope_id: envelope_id)
    end
  end
end
