ngx.header.content_type = "text/plain";
require("bit")
function encrypt(str, key, toBase64)
    r = ngx.md5(key)
    c = 1
    v = ""
    len = string.len(str)
    l = string.len(r)
    for i=1,len do      
        if (c == l+1) 
        then
          c = 1;
        end
        b1 = string.byte(string.sub(str,i,i))
        b2 = string.byte(string.sub(r,c,c))

        bits = bit.bxor(b1, b2)
        chars = string.char(bits)
        v = v..string.sub(r,c,c)..chars
        c = c + 1
    end
    if(toBase64) then
        edres = ed(v,key)
        bas64res = ngx.encode_base64(edres)
        last = string.gsub(bas64res, "+", "-")
        last = string.gsub(last, "/", "_")
        return last
    else 
        return ed(v,key);
    end
end

function ed(str, key)
    r = ngx.md5(key)
    c = 1
    v = ""
    len = string.len(str);
    l = string.len(r);
    for i=1,len do
        if (c == l+1) 
        then
          c=1;
        end
        b1 = string.byte(string.sub(str,i,i))
        b2 = string.byte(string.sub(r,c,c))
        box = bit.bxor(b1,b2)
            chars = string.char(box)
        v = v..chars
        c = c + 1
    end
    return v
end


function decrypt(str,key,toBase64)
    if(toBase64) then
        str = string.gsub(str, "_", "/")
        str = string.gsub(str, "-", "+")
        str = ed(ngx.decode_base64(str),key)
    else
        str = ed(str,key)
    end
    v = ""
    n = 0;
    len = string.len(str)
    for i=1,len,2 do
        md5str = string.sub(str,i,i)    
        n = n + 2
        b1 = string.byte(string.sub(str,n,n))
        b2 = string.byte(md5str) 
        if n <= len then   
          x = bit.bxor(b1, b2)
          v = v..string.char(x)
        end
        
    end
    return v
end

function Split(s, delim)
    if type(delim) ~= "string" or string.len(delim) <= 0 then
        return
    end

    local start = 1
    local t = {}
    while true do
    local pos = string.find (s, delim, start, true) -- plain find
        if not pos then
          break
        end

        table.insert (t, string.sub (s, start, pos - 1))
        start = pos + string.len (delim)
    end
    table.insert (t, string.sub (s, start))

    return t
end


function Gsplit(str)
	local str_tb = {}
	if string.len(str) ~= 0 then
		for i=1,string.len(str) do
			new_str= string.sub(str,i,i)			
			if (string.byte(new_str) >=48 and string.byte(new_str) <=57) or (string.byte(new_str)>=65 and string.byte(new_str)<=90) or (string.byte(new_str)>=97 and string.byte(new_str)<=122) then 				
				table.insert(str_tb,string.sub(str,i,i))				
			else
				return nil
			end
		end
		return str_tb
	else
		return nil
	end
end

local AD_PIN = "website_ad_pin"
local CRYPT_KEY = "website_ad"
local device_id = ""


--sort args
local tab = {}
local uri_args = ngx.req.get_uri_args()  
local adPars = {"tid","id","v","channel","uid","p","ats"}

for k, v in pairs(adPars) do
  if uri_args[v] == nil or uri_args[v] == "" then
    ngx.say("miss " .. v .. " pars")
    ngx.exit(403)
  end
end
for k, v in pairs(uri_args) do  
      table.insert(tab,k)
end 
table.sort(tab)
--set new args value
local newArgs = ""
for _, v in pairs(tab) do
    if v ~= "sig" and v ~="version" then
     	local kv = v.."="..uri_args[v].."&"
        newArgs = newArgs..kv
    end
end 
newArgs = string.sub(newArgs,0,string.len(newArgs)-1)
local sig = ngx.md5(newArgs..AD_PIN)
local sig_arr = Gsplit(sig) 
local sctStr=sig_arr[1]..sig_arr[6]..sig_arr[3]..sig_arr[11]..sig_arr[17]..sig_arr[9]..sig_arr[21]..sig_arr[27]
if uri_args["sig"] ~= sctStr then
--    ngx.say("sErr")
--    ngx.exit(403)
end
-- verify sig end
local uid = ngx.var.arg_uid or ngx.var.cookie_uid
uid = tonumber(uid)
local uidType = type(uid)
if uidType ~= "number" then
  uid = 0
end
-- loop print ulog
local tids = Split(ngx.unescape_uri(uri_args["tid"]),"|")
local ids = Split(ngx.unescape_uri(uri_args["id"]),"|")
local pages = Split(ngx.unescape_uri(uri_args["p"]),"|")
local values = Split(ngx.unescape_uri(uri_args["v"]),"|")
local ats = Split(ngx.unescape_uri(uri_args["ats"]),"|")

if uri_args["ua"] == nil or uri_args["ua"]=="" then
   newArgs = newArgs.."&ua="..ngx.var.http_user_agent
end
if uri_args['channel'] ~= 'app'  then
   if ngx.var.cookie___utrace == nil or ngx.var.cookie___utrace =="" then
	cc = ngx.md5(ngx.var.remote_addr .. ngx.var.http_user_agent);
	ngx.header['Set-Cookie'] = {'__utrace=' .. cc .. '; path=/;Expires='..ngx.http_time( ngx.time() + 864000000 )..';httponly'}
	ccStr = "&cc="..cc
   else
	ccStr = "&cc="..ngx.var.cookie___utrace
   end 
   newArgs = newArgs..ccStr
else
  -- newArgs = string.gsub(newArgs, "cc="..uri_args["cc"] , "cc="..ngx.md5(uri_args["cc"]))
end
for k,v in pairs(tids) do
   -- string replace
   local logStr = string.gsub(ngx.unescape_uri(newArgs), ngx.unescape_uri(uri_args["tid"]) , v)
   logStr = string.gsub(logStr, ngx.unescape_uri(uri_args["id"]) , ids[k])
   logStr = string.gsub(logStr, ngx.unescape_uri(uri_args["p"]) , pages[k])
   logStr = string.gsub(logStr, ngx.unescape_uri(uri_args["v"]) , values[k])
   logStr = string.gsub(logStr, ngx.unescape_uri(uri_args["ats"]) , ats[k])
   if uri_args["ip"] == nil or uri_args["ip"] =="" then
	ipStr = "&ip="..ngx.var.remote_addr	
   else
	ipStr = "&ip="..uri_args["ip"]
   end  
   logStr = string.gsub(logStr, "｜" , "_")
   logStr = string.gsub(logStr, "•" , "#")
   ngx.location.capture('/i-ulog?'..logStr..ipStr)
end
