class Error
  def self.log(exception, opts={})
    Airbrake.notify(exception, opts) if SETTINGS["ENV"] != "test"
    nil
  end
end