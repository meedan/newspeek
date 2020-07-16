class Error
  def self.log(exception, opts={})
    Airbrake.notify(exception, opts) if Settings.get("ENV") != "test"
    nil
  end
end