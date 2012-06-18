require 'multipart_post'
require 'parts'

Parts::ParamPart.class_eval do
  def build_part(boundary, name, value)
    part = "\r\n" #Add a leading carriage return line feed (not sure why DocuSign requires this)
    part << "--#{boundary}\r\n"
    part << "Content-Type: application/json\r\n" #Add the content type which isn't present in the multipart-post gem, but DocuSign requires
    part << "Content-Disposition: form-data; name=\"#{name.to_s}\"\r\n"
    part << "\r\n"
    part << "#{value}\r\n"
  end
end
