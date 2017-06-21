require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

class SheetFetcher

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Lunch Roulette client'
  CLIENT_SECRETS_PATH = 'config/client_secret.json'
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                               "sheets.googleapis.com-lunch-roulette-client.yaml")
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user's default browser will be launched to approve the request.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def self.authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(
      client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(
        base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the " +
           "resulting code after authorization"
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  # Initialize the API
  def self.initialize_api
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
    service
  end

  def self.download_sheet
    # https://docs.google.com/spreadsheets/d/1cUx7UEk-_AHPWynJDF-1ye9laoPDsElyjNbN9e8JK4g/edit
    spreadsheet_id = '1cUx7UEk-_AHPWynJDF-1ye9laoPDsElyjNbN9e8JK4g'
    range = 'Staff_test!A:I'
    response = initialize_api.get_spreadsheet_values(spreadsheet_id, range)
    response.values
  end

  def self.fetch
    sheet = download_sheet
    headers = sheet[0]
    data = sheet[1..-1]
    data.map do |row|
      headers.zip(row).to_h
    end
  end
  # puts 'Name, Lunchable:'
  # puts 'No data found.' if response.values.empty?
  # puts response.inspect

  # employees = response.values.map do |row|
  #   Hash.new()
  #   # Print columns A and E, which correspond to indices 0 and 4.
  #   puts "#{row[1]}, #{row[8]}"
  # end
end
