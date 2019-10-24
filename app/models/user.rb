require 'bcrypt'
class User < ApplicationRecord
  validates_uniqueness_of :name
  include BCrypt

  def password #驗證
    @password ||= Password.new(password_encrypted)
  end

  def password=(new_password) #註冊
    @password = Password.create(new_password)
    self.password_encrypted = @password
  end
end