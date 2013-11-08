module DocusignRest
  class Utility
    # Public takes a path to redirect to and breaks the redirect out of an iFrame
    #
    # This can be used after embedded signing is either successful or not and has
    # been redirected to a controller action (like docusign_response for instance)
    # where the return from the signing process can be evaluated. If successful
    # use this to redirect to one place, otherwise redirect to another place. You
    # can use params[:event] to evaluate whether or not the signing was successful
    #
    # path - a relative or absolute path or rails helper can be passed in
    #
    # Example
    #
    #   class SomeController < ApplicationController
    #
    #     # the view corresponding to this action has the iFrame in it with the
    #     # @url as it's src. @envelope_response is populated from either:
    #     # @envelope_response = client.create_envelope_from_document
    #     # or
    #     # @envelope_response = client.create_envelope_from_template
    #     def embedded_signing
    #       client = DocusignRest::Client.new
    #       @url = client.get_recipient_view(
    #         envelope_id: @envelope_response["envelopeId"],
    #         name: current_user.display_name,
    #         email: current_user.email,
    #         return_url: "http://localhost:3000/docusign_response"
    #       )
    #     end
    #
    #     def docusign_response
    #       utility = DocusignRest::Utility.new
    #
    #       if params[:event] == "signing_complete"
    #         flash[:notice] = "Thanks! Successfully signed"
    #         render :text => utility.breakout_path(posts_path), content_type: 'text/html'
    #       else
    #         flash[:notice] = "You chose not to sign the document."
    #         render :text => utility.breakout_path(logout_path), content_type: 'text/html'
    #       end
    #     end
    #
    #   end
    #
    # Returns a string of HTML including some JS to redirect to the passed in
    # path but in the iFrame's parent.
    def breakout_path(path)
      "<html><body><script type='text/javascript' charset='utf-8'>parent.location.href = '#{path}';</script></body></html>"
    end
  end
end
