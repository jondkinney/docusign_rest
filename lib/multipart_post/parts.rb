require 'multipart_post'
require 'parts'

Parts::ParamPart.class_eval do
  def build_part(boundary, name, value, headers = {})
    part = ""
    part << "--#{boundary}\r\n"

    # TODO (2014-02-03) jonk => multipart-post seems to allow for adding
    # a configurable header, hence the headers param in the method definition
    # above. However, I can't seem to figure out how to acctually get it passed
    # all the way through to line 42 of the Parts module in the parts.rb file.
    # So for now, we still monkeypatch the content-type in directly.

    part << "Content-Type: application/json\r\n"
    part << "Content-Disposition: form-data; name=\"#{name.to_s}\"\r\n"
    part << "\r\n"
    part << "#{value}\r\n"
  end
end
