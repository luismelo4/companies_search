require 'rails_helper'

RSpec.describe 'Admin', type: :request do
  describe 'GET /admin' do
    it 'shows admin dashboard with company count' do
      Company.create!(coc_number: '12345678', company_name: 'Test Corp', city: 'Amsterdam')
      
      get '/admin'
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('1')
      expect(response.body).to include('Total Companies')
    end
  end

  describe 'POST /admin/import_csv' do
    let(:temp_csv) do
      file = Tempfile.new(['test', '.csv'])
      CSV.open(file.path, 'w', col_sep: ';') do |csv|
        csv << ['coc_number', 'company_name', 'city']
        csv << ['12345678', 'Test Corp', 'Amsterdam']
      end
      file
    end
    
    let(:csv_file) do
      Rack::Test::UploadedFile.new(temp_csv.path, 'text/csv')
    end

    context 'when file is provided' do
      it 'delegates to CompanyImportService' do
        mock_result = CompanyImportService::ImportResult.new(
          total_processed: 1,
          duplicates_removed: 0,
          final_count: 1
        )
        
        expect(CompanyImportService).to receive(:import_from_file).and_return(mock_result)
        
        post '/admin/import_csv', params: { csv_file: csv_file }
        
        expect(response).to redirect_to(admin_path)
        expect(flash[:success]).to be_present
      end

      it 'handles successful import' do
        mock_result = CompanyImportService::ImportResult.new(
          total_processed: 5,
          duplicates_removed: 2,
          final_count: 3
        )
        
        allow(CompanyImportService).to receive(:import_from_file).and_return(mock_result)
        
        post '/admin/import_csv', params: { csv_file: csv_file }
        
        expect(flash[:success]).to include('5')
        expect(flash[:success]).to include('2')
        expect(flash[:success]).to include('3')
      end

      it 'handles import errors' do
        mock_result = CompanyImportService::ImportResult.new(error: 'File is corrupted')
        
        allow(CompanyImportService).to receive(:import_from_file).and_return(mock_result)
        
        post '/admin/import_csv', params: { csv_file: csv_file }
        
        expect(flash[:error]).to include('File is corrupted')
      end
    end

    context 'when file is not provided' do
      it 'sets error message and redirects' do
        post '/admin/import_csv'
        
        expect(response).to redirect_to(admin_path)
        expect(flash[:error]).to include('Please select a CSV file')
      end
    end
  end

  describe 'POST /admin/clear_data' do
    before do
      Company.create!(coc_number: '12345678', company_name: 'Test Corp', city: 'Amsterdam')
    end

    it 'clears all company data' do
      expect { post '/admin/clear_data' }.to change { Company.count }.from(1).to(0)
      expect(response).to redirect_to(admin_path)
      expect(flash[:success]).to include('cleared')
    end
  end
end

