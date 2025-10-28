class AdminController < ApplicationController
  def index
    @companies_count = Company.count
  end

  def import_csv
    unless params[:csv_file].present?
      flash[:error] = "Please select a CSV file to upload."
      return redirect_to admin_path
    end

    result = CompanyImportService.import_from_file(params[:csv_file].path)

    if result.success?
      flash[:success] = result.success_message
    else
      flash[:error] = "Error importing CSV: #{result.error}"
    end

    redirect_to admin_path
  end

  def clear_data
    Company.delete_all
    flash[:success] = "All company data has been cleared."
    redirect_to admin_path
  end
end
