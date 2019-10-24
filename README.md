# 在Rails使用bcrypt-ruby製作使用者認證
在有些輕量的專案，可能不需要使用龐大的Devise，或是覺得要特殊設置Devise比較不方便去修改的時候。自己刻一個反而會變成比較快的選項。

[bcrypt-ruby](https://github.com/codahale/bcrypt-ruby)的github頁面

附註：Rails附有已經做好比較方便使用的[has_secure_password](https://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html#method-i-has_secure_password)方法。

本篇的目標是做出一個可以登入登出的使用者認證。
* 註冊並加密密碼
* 登入建立session給使用者cookie
* 登出刪除session

## bcrypt() 是如何運作的？
使用者密碼 -> bcrypt不可回復加密 -> 儲存用的加密後密碼\
John1234   -> bcrypt不可回復加密 -> $2a$12$f3naZucp1nvrE8GBtsUgW.b/nWKRLTZpNooPuNmI3ZIXeeGbjSLavi

## 使用bcrypt
bcrypt提供兩個方法

* 使用 `BCrypt::Password.create()`方法來加密密碼
```ruby
require ‘bcrypt’
@password = BCrypt::Password.create(“finn_the_human”)
@password #=> “$2a$12$u7zLQcHcad2t4Qs0byVpBOD365Y0.v/jakz7ozPtUEbxG8zbB7aCvG”
```

* 使用`BCrypt::Password.new()`方法來驗證密碼
```ruby
require ‘bcrypt’
@db_password = BCrypt::Password.new(@user.password)
# 檢查密碼
@db_password == “finn_the_human” #=> true # 密碼正確
@db_password == “jack_the_dog”  #=> false # 密碼錯誤
```

## 實作
本篇使用版本: Rails 6, Ruby 2.6.5

### 建立新的Rails 專案
`$ rails new learnbcrypt`
`$ cd learnbcrypt`

### 在Gemfile加入bcrypt
打開Gemfile加入bcrypt
bcrypt已經有附在預設的Gemfile裡，取消bcrypt前面的#註解即可。
`$ bundle`

### 建立一個首頁
做一個簡單的頁面讓我們放登入表格
`$ rails g controller users index`
在`config/routes.rb`加入首頁連結
```ruby
Rails.application.routes.draw do
  root ‘users#index’
end
```

為了方便測試我們把登入註冊都放在首頁裡面
`app/views/users/index.html.erb`
```erb
<h1><%= link_to ‘Learn Bcrypt!’, root_path%></h1>

<h2>登入狀態</h2>
ID: <%= @current_id %><br>
Username: <%= @current_name %><br>
<%= link_to “登出” , logout_path, method: :delete %>

<h2>登入</h2>
<%= form_with url: login_path do |log|%>
<%= log.label :name%>
<%= log.text_field :name%>
<%= log.label :password%>
<%= log.password_field :password %>
<%= log.submit '登入'%>
<% end %>

<h2>註冊使用者</h2>
<%= form_with model: @user do |form| %>
<%= form.label :name%>
<%= form.text_field :name%>
<%= form.label :password%>
<%= form.password_field :password %>
<%= form.submit%>
<% end %>

<h2>所有的使用者</h2>
<ul>
<% @users.each do |user|%>
<li>ID: <%= user.id %>, 帳號: <%= user.name %>, 密碼: <%= user.password %></li>
<% end %>
</ul>

```

### 建立使用者Model
`$ rails g model user name password_encrypted`
`$ rails db:migrate`

在`app/models/user.rb`帶入bcrypt並加入`Password.new()`與`Password.create()`方法
```
require ‘bcrypt’
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
```


### 在users_controller做註冊功能
`app/controllers/users_controller.rb`
```
class UsersController < ApplicationController

  def index #這個方法提供登入狀態給首頁
    @user = User.new
    @users = User.all
    @current_id = session[:current_user_id]
    @current_name = User.find(@current_id).name if @current_id
  end

  def create #註冊帳號
    @user = User.new(filted_params)
    @user.password = filted_params[:password]
    if @user.save!
      redirect_to root_path
    else
      render :index
    end
  end

 
private

  def filted_params
    params.require(:user).permit(:name, :password)
  end

end
```

### 加入SessionController與登入功能
加入SessionController
`$ rails g controller session`

更正`config/routes.rb`的路徑
```
Rails.application.routes.draw do
  get ‘users/index’
  root ‘users#index’
  post ‘login’, to: ‘session#login’, as: ‘login’
  delete ‘login’, to: ‘session#destroy’, as: ‘logout’
	resources :users
end

```

在`app/controllers/session_controller.rb`
```
class SessionController < ApplicationController
  def login #登入方法
    @user = User.find_by(name: params[:name])
    if @user.password == params[:password]#檢驗密碼
		#建立session給登入者cookie
      session[:current_user_id] = @user.id 
    else
      render :index
    end
    redirect_to root_path
  end

  def destroy #登出刪除session
    session.destroy
    redirect_to root_path
  end
end

```

### 啟動專案
`$ rails s`
