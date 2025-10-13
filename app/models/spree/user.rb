class Spree::User < Spree.base_class
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable, :invitable,

  # Spree modules
  include Spree::UserAddress
  include Spree::UserMethods
  include Spree::UserPaymentSource
end
