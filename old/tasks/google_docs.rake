desc "Update all YAML files from Google Docs"
task :google_docs do
  require 'fileutils'
  require 'google_drive'
  require 'yaml'

  data_folder = "#{Rails.root}/db/data"

  FileUtils.rmdir   data_folder
  FileUtils.mkdir_p data_folder

  session = GoogleDrive.login ENV['GOOGLE_DRIVE_LOGIN'], ENV['GOOGLE_DRIVE_PASSWORD']

  # Don't change worksheet order here, or in Google Docs without fixing both!
  ["returns", "tbill", "inflation", "etfs", "market_portfolio", 'real_estate'].each_with_index do |data_type, index|
    rows = session.spreadsheet_by_key(ENV['GOOGLE_DRIVE_SPREADSHEET_KEY']).worksheets[index].rows.dup
    File.open("#{Rails.root}/db/data/#{data_type}.yml", 'w') { |file| file.write(YAML.dump(rows)) }
  end
end
