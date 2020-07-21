class Error
  def self.log(exception, opts={})
    Airbrake.notify(exception, opts) unless Settings.blank?('airbrake_api_host')
    nil
  end
end
