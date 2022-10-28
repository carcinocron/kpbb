
struct Password
end

def plaintext_password : String
  "password1"
end

def hashed_password : String
  # puts Crypto::Bcrypt::Password.create(plaintext_password, cost: 4)
  "$2a$04$3IjN5WFGc8.mXq8lr.IWBe/KK2aFcu.nq497Fm3DbgOqeZbsepP8i"
end
