EMAIL_DOMAIN = 'example.com'
God::Contacts::Email.message_settings = {
  :from           => opts[:email][:from_username], }
God.contact(:email) do |c|
  c.name          = opts[:email][:to_username],
  c.email         = opts[:email][:to_username],
end

#
# GMail
#
# http://millarian.com/programming/ruby-on-rails/monitoring-thin-using-god-with-google-apps-notifications/
require 'tlsmail'
Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
God::Contacts::Email.server_settings = {
  :address        => 'smtp.gmail.com',
  :tls            => 'true',
  :port           => 587,
  :domain         => opts[:email][:domain],
  :user_name      => opts[:email][:from_username],
  :password       => opts[:email][:from_password],
  :authentication => :plain
}

# #
# # SMTP email
# #
# God::Contacts::Email.server_settings = {
#   :address        => "smtp.example.com",
#   :port           => 25,
#   :domain         => opts[:email][:domain],
#   :user_name      => opts[:email][:from_username],
#   :password       => opts[:email][:from_password],
#   :authentication => :plain,
# }
