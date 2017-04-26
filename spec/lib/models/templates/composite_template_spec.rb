describe Docusign::CompositeTemplate do

  describe "#to_h" do
    subject { template.to_h }

    context "with server templates" do
      let(:template) { FactoryGirl.build(:composite_template, :with_server_templates) }
      let(:server_templates) { template.server_templates }
      its(:keys) { is_expected.to eq([:serverTemplates]) }
      its([:serverTemplates]) { is_expected.to eq(server_templates.map(&:to_h)) }
    end

    context "with inline templates" do
      let(:template) { FactoryGirl.build(:composite_template, :with_inline_templates) }
      let(:inline_templates) { template.inline_templates }
      its(:keys) { is_expected.to eq([:inlineTemplates]) }
      its([:inlineTemplates]) { is_expected.to eq(inline_templates.map(&:to_h)) }
    end
  end
end
