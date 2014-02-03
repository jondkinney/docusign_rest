require 'multipart_post'
require 'parts'

Parts::ParamPart.class_eval do
  def build_part(boundary, name, value)
    part = ""
    part << "--#{boundary}\r\n"
    part << "Content-Type: application/json\r\n" #Add the content type which isn't present in the multipart-post gem, but DocuSign requires
    part << "Content-Disposition: form-data; name=\"#{name.to_s}\"\r\n"
    part << "\r\n"
    part << "#{value}\r\n"
  end
end
