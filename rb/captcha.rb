# encoding: UTF-8
require 'deathbycaptcha'
module Captcha
  CAPTCHA_CLIENT = DeathByCaptcha.http_client('kyjunfly', 'password') # erase password!!

  def self.get_captcha_value(url)

    response = CAPTCHA_CLIENT.decode(url)

    captcha_value = response["text"]

    puts "captcha_key : #{captcha_key}, captcha_value : #{captcha_value}"

    return captcha_key, captcha_value
  end
end
