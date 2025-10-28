class CompanySearchService
  MIN_QUERY_LENGTH = 2
  MAX_SUGGESTIONS = 10
  SUGGESTIONS_PER_TYPE = 5

  def initialize(query)
    @query = query
  end

  def call
    autocomplete_suggestions
  end

  private

  def autocomplete_suggestions
    return [] if @query.blank? || @query.length < MIN_QUERY_LENGTH
    
    suggestions = []
    
    # Search for company names
    company_names = Company.search_by_name(@query)
                          .limit(SUGGESTIONS_PER_TYPE)
                          .pluck(:company_name)
                          .map { |name| { text: name, type: 'Company Name' } }
    
    # Search for cities
    cities = Company.search_by_city(@query)
                   .limit(SUGGESTIONS_PER_TYPE)
                   .pluck(:city)
                   .map { |city| { text: city, type: 'City' } }
    
    # Search for CoC numbers
    coc_numbers = Company.search_by_coc_number(@query)
                        .limit(SUGGESTIONS_PER_TYPE)
                        .pluck(:coc_number)
                        .map { |number| { text: number, type: 'CoC Number' } }
    
    # Combine and deduplicate by text value
    suggestions = (company_names + cities + coc_numbers).uniq { |item| item[:text] }
    
    # Return limited suggestions
    suggestions.first(MAX_SUGGESTIONS)
  end
end

