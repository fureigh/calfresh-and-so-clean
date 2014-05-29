require 'sinatra'
require 'rack/ssl'
require './calfresh'
require './faxer'
require './emailer'
require 'pry'

class CalfreshWeb < Sinatra::Base
  use Rack::SSL unless settings.environment == :development


  get '/' do
    erb :index
  end

  post '/applications' do
    writer = Calfresh::ApplicationWriter.new
    input_for_writer = params
    input_for_writer[:sex] = case params[:sex]
      when "Male"
        "M"
      when "Female"
        "F"
      else
        ""
    end
    input_for_writer[:name_page3] = params[:name]
    input_for_writer[:ssn_page3] = params[:ssn]
    @application = writer.fill_out_form(input_for_writer)
    if @application.has_pngs?
      @verification_docs = Calfresh::VerificationDocSet.new(params)
      images_to_send = @application.png_file_set
      images_to_send << @verification_docs.file_array
      puts images_to_send
      #@result = Faxer.send_fax(ENV['FAX_DESTINATION_NUMBER'], images_to_send)
      @result = Emailer.send_calfresh_application(images_to_send)
      erb :after_fax
    else
      puts "No PNGs! WTF!?!"
      redirect to('/')
    end
  end

  get '/applications/:id' do
    send_file Calfresh::Application.new(params[:id]).signed_png_path
  end
end
