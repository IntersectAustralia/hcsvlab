require 'blacklight/catalog'

require 'ostruct'

class TranscriptsController < ApplicationController
  respond_to :html, :xml

  include Blacklight::Catalog
  include Blacklight::BlacklightHelperBehavior

  MEDIA_ITEM_FIELDS = %w(title   description recorded_on copyright license format media depositor)

  def show
    # documents = get_solr_response_for_doc_id(params['id'])[0]
    # document = documents['response']['docs'][0]
    # attributes = document_to_attribues(document)
    # media = get_media('video', params['url'])
    # attributes['media'] = media

    # @media_item = MediaItem.new attributes
    
    file = OpenStruct.new
    file.path = '/Users/ilya/Downloads/eopas.xml'
    # file.path = '/Users/ilya/Downloads/toukelauMov.xml' 
    source = OpenStruct.new
    source.file = file
    depositor = OpenStruct.new
    depositor.full_name = "Joe Bloggs"
    params = { source: source, transcript_format: 'EOPAS', depositor: depositor, title: 'Test', date: '2000-04-07 00:00:00 UTC', country_code: 'AU', language_code: 'eng'}

    transcript = Transcript.new params
    transcript.create_transcription

    @transcript = transcript

    logger.warn "TR: #{@transcript.inspect}"
    logger.warn "TR: #{@transcript.phrases}"
    # @transcripts = [transcript]
  end


  def solr_doc_to_hash(solr_document)
    result = {}
    solr_document.each do |key, value|
      key = key.split('/')[-1].split('#')[-1].split('_')[0..-2].join('_')
      value = value[0] unless value.size > 1
      result[key] = value
    end
    result
  end

  def get_media(type, url)
    media = OpenStruct.new
    if type == 'audio'
      audio = OpenStruct.new
      audio.url = url
      media.audio = audio
    elsif type == 'video'
      video = OpenStruct.new
      # video.url = url
      video.url = 'file:///Users/ilya/Downloads/NT5-TokelauThatch-Vid104.ogg'
      media.video = video
      poster = OpenStruct.new
      poster.url = 'http://konstantkitten.com/wp-content/uploads/kittne4.jpg'
      media.poster = poster
    end
    media
  end

  def document_to_attribues(document)
    attributes = solr_doc_to_hash(document)  
    attributes['format'] = 'video'

    attributes['recorded_on'] = attributes['created']
    attributes['copyright'] = attributes['rights']
    attributes['license'] = attributes['rights']

    depositor = OpenStruct.new
    depositor.full_name = attributes['depositor']
    attributes['depositor'] = depositor

    attributes.delete_if {|key, value| !MEDIA_ITEM_FIELDS.include? key}
    attributes
  end



  # filter_access_to :all
  # before_filter :terms_agreement, :only => [:index, :show]

  # def index
  #   if params[:commit] == 'Clear'
  #     params[:search] = ""
  #   end

  #   if current_user and current_user.admin?
  #     @transcripts = Transcript.scoped
  #   else
  #     @transcripts = Transcript.current_user_and_public(current_user).search params[:search]
  #   end

  #   if params[:language_code]
  #     @transcripts = @transcripts.where :language_code => params[:language_code]
  #   end

  #   # sort by a given column
  #   if params[:sort] == "media_item"
  #     @transcripts = @transcripts.sort_by {|a| a.media_item ? a.media_item.title : ""}
  #   else
  #     # make sure we got passed a valid column to sort by
  #     if Transcript.column_names.find_index(params[:sort])
  #       @transcripts = @transcripts.sort_by {|a| a.send(params[:sort]).to_s}
  #     else
  #       @transcripts = @transcripts.sort_by {|a| a.title ? a.title : ""}
  #     end
  #   end

  #   # reverse order if requested
  #   if params[:direction] == "desc"
  #     @transcripts = @transcripts.reverse
  #   end

  #   # FIXME: pagination
  #   #@transcripts = @transcripts.per(20).page(params[:page])
  # end

  # def show
  #   # if current_user and current_user.admin?
  #   #   @transcript = Transcript.find params[:id]
  #   # else
  #   #   @transcript = Transcript.current_user_and_public(current_user).find params[:id]
  #   # end

  #   # @media_item = @transcript.media_item

  #   # TODO Pick some better filename dynamically
  #   respond_with @transcript do |format|
  #     format.html { @transcript }
  #     format.xml do
  #       headers["Content-Disposition"] = "attachment; filename=\"eopas.xml\""
  #       @transcript
  #     end
  #   end
  # end


  # def new
  #   @transcript = Transcript.new
  # end

  # def create
  #   @transcript = current_user.transcripts.build params[:transcript]

  #   options = Hash.new
  #   if @transcript.save
  #     flash[:notice] = 'Transcript was successfully validated and added, please edit automatically discovered values'
  #     options[:location] = edit_transcript_path @transcript
  #   end

  #   respond_with @transcript, options
  # end

  # def edit
  #   if current_user and current_user.admin?
  #     @transcript = Transcript.find params[:id]
  #   else
  #     @transcript = current_user.transcripts.find params[:id]
  #   end
  #   (3 - @transcript.participants.size).times { @transcript.participants.build }
  # end

  # def update
  #   if current_user and current_user.admin?
  #     @transcript = Transcript.find params[:id]
  #   else
  #     @transcript = current_user.transcripts.find params[:id]
  #   end
  #   if @transcript.update_attributes(params[:transcript])
  #     flash[:notice] = 'Transcript was successfully updated.'
  #   end

  #   respond_with @transcript
  # end

  # def destroy
  #   if current_user and current_user.admin?
  #     @transcript = Transcript.find params[:id]
  #   else
  #     @transcript = current_user.transcripts.find params[:id]
  #   end

  #   @transcript.destroy
  #   flash[:notice] = 'Transcript deleted!'

  #   redirect_to transcripts_path
  # end

  # filter_access_to :remove_media_item, :require => :delete
  # def remove_media_item
  #   @transcript = current_user.transcripts.find params[:id]
  #   @transcript.media_item_id = nil
  #   @transcript.save
  #   flash[:notice] = 'Media detached!'

  #   redirect_to @transcript
  # end


  # filter_access_to :new_attach_media_item, :require => :new
  # def new_attach_media_item
  #   if current_user and current_user.admin?
  #     @transcript = Transcript.find params[:id]
  #   else
  #     @transcript = current_user.transcripts.find params[:id]
  #   end
  #   @media_items = MediaItem.current_user_and_public(current_user)
  # end

  # filter_access_to :create_attach_media_item, :require => :create
  # def create_attach_media_item
  #   if current_user and current_user.admin?
  #     @transcript = Transcript.find params[:transcript_id]
  #   else
  #     @transcript = current_user.transcripts.find params[:transcript_id]
  #   end

  #   if current_user and current_user.admin?
  #     @media_item = MediaItem.find params[:media_item_id]
  #   else
  #     @media_item = MediaItem.current_user_and_public(current_user).find params[:media_item_id]
  #   end

  #   @transcript.media_item = @media_item

  #   flash[:notice] = 'Media Item was added to transcript' if @transcript.save

  #   respond_with @transcript
  # end

  # private
  # def terms_agreement
  #   return if current_user
  #   return if session[:agreed_to_terms]

  #   store_location
  #   redirect_to show_terms_users_path
  # end

end
