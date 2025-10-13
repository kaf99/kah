# app/models/spree/user.rb
# Include default devise modules. Others available are:
# :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
class Spree::User < Spree::Base
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable, :invitable

  include Spree::UserAddress
  include Spree::UserMethods
  include Spree::UserPaymentSource
end
