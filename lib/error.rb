class Error
  def self.log(exception)
    Airbrake.notify(exception) if SETTINGS["ENV"] != "test"
    nil
  end
end