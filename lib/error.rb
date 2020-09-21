class Error
  def self.log(exception, opts={})
    Airbrake.notify(exception, opts) unless Settings.airbrake_specified?
    raise exception if Settings.airbrake_unspecified?
    nil
  end
end
