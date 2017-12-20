ngx.header.content_type = "text/plain";
if ngx.var.arg_cc ~= nil and ngx.var.arg_cc ~="" then
  device_id = ngx.md5(ngx.var.arg_cc)
else
  device_id = ngx.var.cookie___utrace
end
if not device_id then
 device_id =  ngx.md5(ngx.var.remote_addr .. ngx.var.http_user_agent);
 ngx.header['Set-Cookie'] = {'__utrace=' .. device_id .. '; path=/;Expires='..ngx.http_time( ngx.time() + 864000000 )..';httponly'}
end
local uid = ngx.var.arg_uid or ngx.var.cookie_uid
uid = tonumber(uid)
local uidType = type(uid)
if uidType ~= "number" then
  uid = "-"
end
local args = string.gsub(ngx.var.args, "%%7C" , "|") 
args = string.gsub(args, "|" , "_")  
args = string.gsub(args, "uid=" , "uid2=")
args = string.gsub(args, "｜" , "_")
args = string.gsub(args, "•" , "#")
local cc = ngx.location.capture('/i-log?'.. args ..'&cc='..device_id..'&uid='..uid)
