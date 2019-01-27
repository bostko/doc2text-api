class ProcessBinaryController < ApplicationController
  include ActionController::Live

  def odt
    uploaded_file = params[:odt_file]
    raise ActionController::BadRequest.new, "Please send multipart form data with odt_file.\n" +
      'curl -X POST -F "odt_file=@./test.odt;type=application/vnd.oasis.opendocument.text" http://localhost:3000/process_binary/odt' unless validate uploaded_file
    input_file_path = uploaded_file.path
    response.headers['Content-Type'] = 'text/markdown; charset=UTF-8'
    odt = Doc2Text::Odt::Document.new input_file_path
    begin
      odt.unpack
      styles_xml_root = odt.parse_styles
      markdown = Doc2Text::Markdown::OdtParser.new response.stream, styles_xml_root
      begin
        odt.parse markdown
      ensure
       markdown.close
      end
    ensure
      odt.clean
    end
    File.delete uploaded_file.tempfile
  end

  private
  def validate(uploaded_file)
    not uploaded_file.nil? and uploaded_file.is_a? ActionDispatch::Http::UploadedFile and uploaded_file.content_type == "application/vnd.oasis.opendocument.text"
  end
end
