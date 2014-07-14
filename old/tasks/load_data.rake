task load_data:   ["load_data:securities_etfs"]

namespace :load_data do

  desc "Load Securities & ETF's from YAML file"
  task securities_etfs: :environment do

    etf_file      = "#{Rails.root}/db/data/etfs.yml"
    raise "File does not exist. You probably need to run rake google_docs." unless File.exists?(etf_file)

    ## Clear the DB ##

    # NB: delete_all skips validations - otherwise it wont let us delete
    # securities as they are in use by portfolios.
    Etf.delete_all
    Security.delete_all

    ## Perform reverse portfolio optimization to determine implied returns ##
    implied_returns = Finance::ReversePortfolioOptimization.perform

    ## Load data from YAML files, and load into DB ##
    etf_data          = YAML.load(File.read etf_file)
    etf_data_headers  = etf_data.shift
    return_data       = Finance::ReturnData.values

    etf_ticker_index      = etf_data_headers.index("etf_ticker")
    description_index     = etf_data_headers.index("description")
    asset_type_index      = etf_data_headers.index("asset_type")
    asset_class_index     = etf_data_headers.index("asset_class")
    security_ticker_index = etf_data_headers.index("security_ticker")
    raise "Column header missing" if [etf_ticker_index, description_index,
      asset_type_index, asset_class_index, security_ticker_index].any? {|el| el.nil?}

    etf_data.each do |row|
      security_ticker = row[security_ticker_index].strip
      security = Security.find_by(ticker: security_ticker)
      if security.nil?
        historical_returns = return_data[security_ticker].to_a # Comes as a vector, but need as array for mean/sd below, and storing to DB
        properties = {
          ticker: security_ticker,
          asset_class: row[asset_class_index],
          asset_type: row[asset_type_index],
          implied_return: implied_returns[security_ticker],
          returns: historical_returns
        }
        security = Security.create! properties
      end
      security.etfs.create!({ticker: row[etf_ticker_index], description: row[description_index]})
    end

  end # securities_etfs

end # load_data namespace
