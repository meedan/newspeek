class Error
  def self.log(exception, opts={}, should_raise=Settings.airbrake_unspecified?)
    Airbrake.notify(exception, opts) unless Settings.airbrake_specified?
    raise exception if should_raise
    nil
  end
end
