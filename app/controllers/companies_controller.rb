class CompaniesController < ApplicationController
  PER_PAGE = 20

  def index
    @companies = Company.paginated(page: params[:page], per_page: PER_PAGE)
  end

  def search
    @companies = Company.search(params[:q])
                        .paginated(page: params[:page], per_page: PER_PAGE)

    respond_to do |format|
      format.html { render partial: 'search_results', locals: { companies: @companies } }
      format.json { render json: { companies: @companies.map(&:as_json) } }
    end
  end

  def autocomplete
    suggestions = CompanySearchService.new(params[:q]).call
    render json: { suggestions: suggestions }
  end
end
