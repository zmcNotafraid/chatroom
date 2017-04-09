An open-source chatroom
=======================

This chatroom is only chat through phoenix websocket.You need to pass jwt token to include user info.

## Getting Started

### Phoenix

#### development
##### 1. copy config/dev.exs.example to config/dev.exs

##### 2. replace private_key and secret_key_base in config/dev.exs

##### 3. install dependencies and run server

```elixr
mix deps.get && mix phoenix.server
```

##### 3. Using a browser, go to `http://localhost:4000/?xtoken=`

#### production

##### 1. copy config/prod.secret.exs.example to config/prod.secret.exs

##### 2. replace private_key、secret_key_base、host and redis_host in config/prod.secret.exs

##### 3. how to deploy

  use [distillery](https://github.com/bitwalker/distillery)


### Rails

#### 1. add jwt gem

```ruby
gem 'jwt'
```
#### 2. set a chat_token to include user info

```ruby
# app/helpers/application_helper.rb
CHATROOM_ADMIN_LIST = [1,....] #user id

def chat_token
    payload = {
      iss: #user name
      sub: #user unique name
      adi: #user is a admin or not
    }
    JWT.encode payload, private_key, 'HS256' # same as phoenix private_key
end
```
#### 3. pass chat_token

```html
  <iframe frameborder="0" name="Iframe1" src="https://localhost:4000/?xtoken=<%= chatroom_token %>" width="100%" height="450" scrolling="no"></iframe>

```
