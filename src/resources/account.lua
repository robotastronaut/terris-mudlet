local Account = {}

function Account:new(name, conf)
  if type(name) ~= "string" then
    error("Account:new argument error (name): expected string, got "..type(name))
  end

  if #name < 1 then
    error("Account:new argument error (name): name cannot be empty")
  end

  if conf and type(conf) ~= "table" then
    error("Account:new(name, conf): Argument error (conf), expected nil or table, got " .. type(conf))
  end


  local account = {
    name = "Account",
    config = {}
  }

  account.config = conf

  setmetatable(account, self)
  self.__index = self
  return account
end

return Account