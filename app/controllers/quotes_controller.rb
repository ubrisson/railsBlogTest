class QuotesController < ApplicationController
  before_action :set_quote, only: [:show, :edit, :update, :destroy]
  before_action :admin_user, only: [:new, :create, :edit, :update, :destroy, :import]

  # GET /quotes
  def index
    @quote = Quote.new
    @quotes = search_and_tagged_quotes(params)
                  .paginate(page: params[:page], per_page: 15)
    @tags = correct_quotes.tag_counts_on(:tags)
  end

  # GET /quotes/1
  def show; end

  # GET /quotes/new
  def new
    @quote = Quote.new
  end

  # GET /quotes/1/edit
  def edit
    helpers.store_referrer
  end

  # POST /quotes
  def create
    session[:referrer] = request.referer if session[:referrer].nil?
    @quote = Quote.new(quote_params)
    if @quote.save
      flash[:success] = "'#{@quote.title}' successfully created."
    else
      flash[:danger] = 'Failed to create new quote.'
    end
    helpers.redirect_back_or quotes_path
  end

  # PATCH/PUT /quotes/1
  def update
    session[:referrer] = request.referer if session[:referrer].nil?
    if @quote.update(quote_params)
      flash[:success] = "'#{@quote.title}' successfully updated."
      helpers.redirect_back_or quote_path(@quote)
    else
      flash[:danger] = "Failed to edit '#{@quote.title}'."
      render 'quotes/edit'
    end
  end

  # DELETE /quotes/1
  def destroy
    @quote.destroy
    flash[:success] = "'#{@quote.title}' successfully deleted."
    redirect_to quotes_url
  end

  def export
    @quotes = search_and_tagged_quotes(params)
    send_data @quotes.to_json, filename: "quotes_#{params[:q]}.json",
                               type: :json
  end

  def import
    quotes = JSON.parse(File.read(params[:json]))
    quotes.each do |quote|
      Quote.create(quote.to_h)
    end
    flash[:success] = "#{quotes.size} quotes successfully imported."
    redirect_back(fallback_location: quotes_path)
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_quote
    @quote = Quote.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def quote_params
    params.require(:quote).permit(:title, :author, :body, :source,
                                  :tag_list, :commentary, :public)
  end

  def correct_quotes
    logged_in? ? Quote.all.with_tags : Quote.only_public.with_tags
  end

  def search_and_tagged_quotes(params)
    if params[:q]
      tagged = correct_quotes.tagged_with(params[:q]).unscope(:order)
      searched = correct_quotes.search_for(params[:q]).unscope(:order)
      correct_quotes
          .from("(#{tagged.to_sql} UNION #{searched.to_sql}) as Quotes")
    elsif params[:tag]
      correct_quotes.tagged_with(params[:tag])
    else
      correct_quotes
    end
  end
end
