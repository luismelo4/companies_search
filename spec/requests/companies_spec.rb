require 'rails_helper'

RSpec.describe 'Companies', type: :request do
  describe 'GET /companies/search' do
    it 'delegates to Company.search scope and returns JSON results' do
      company = Company.create!(coc_number: '12345678', company_name: 'Test Corp', city: 'Amsterdam')
      search_relation = Company.where(id: company.id)
      
      # Mock the Company.search scope chain
      allow(Company).to receive(:search).with('Test').and_return(search_relation)
      allow(search_relation).to receive(:paginated).and_return(Kaminari.paginate_array([company]))
      allow(company).to receive(:as_json).and_return({
        'id' => company.id,
        'company_name' => 'Test Corp',
        'city' => 'Amsterdam',
        'coc_number' => '12345678'
      })
      
      get '/companies/search', params: { q: 'Test' }, headers: { 'Accept' => 'application/json' }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['companies']).to be_an(Array)
      expect(Company).to have_received(:search).with('Test')
    end

    it 'returns empty results for no matches' do
      empty_relation = Company.none
      allow(Company).to receive(:search).with('NonExistent').and_return(empty_relation)
      allow(empty_relation).to receive(:paginated).and_return(Kaminari.paginate_array([]))
      
      get '/companies/search', params: { q: 'NonExistent' }, headers: { 'Accept' => 'application/json' }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['companies']).to eq([])
    end
  end

  describe 'GET /companies/autocomplete' do
    it 'returns autocomplete suggestions from service' do
      mock_suggestions = [
        { text: 'Test Corp', type: 'Company Name' },
        { text: 'Amsterdam', type: 'City' }
      ]
      
      mock_service = instance_double(CompanySearchService, call: mock_suggestions)
      expect(CompanySearchService).to receive(:new).with('Test').and_return(mock_service)
      
      get '/companies/autocomplete', params: { q: 'Test' }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['suggestions']).to eq(mock_suggestions.map(&:stringify_keys))
    end

    it 'returns empty suggestions for short query' do
      mock_service = instance_double(CompanySearchService, call: [])
      expect(CompanySearchService).to receive(:new).with('T').and_return(mock_service)
      
      get '/companies/autocomplete', params: { q: 'T' }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['suggestions']).to eq([])
    end

    it 'delegates to CompanySearchService' do
      mock_service = instance_double(CompanySearchService, call: [])
      expect(CompanySearchService).to receive(:new).with('query').and_return(mock_service)
      get '/companies/autocomplete', params: { q: 'query' }
    end
  end
end