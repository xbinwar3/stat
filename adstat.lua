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
        --if bits > 10 then
        chars = string.char(bits)
        --else 
        --    chars = ""
        --end
        v = v..string.sub(r,c,c)..chars
        c = c + 1
    end
    --ngx.say(v)
    if(toBase64) then
        edres = ed(v,key)
        --ngx.say(edres)
        bas64res = ngx.encode_base64(edres)
        --ngx.say(bas64res)
        last = string.gsub(bas64res, "+", "-")
        last = string.gsub(last, "/", "_")
        return last
        --ngx.say(last)
       -- return str_replace(array('+','/'),array('-','_'),base64_encode(self::ed($v,$key)));
    else 
        return ed(v,key);
    end
end

function ed(str, key)
    r = ngx.md5(key)
    --ngx.say(r)
    c = 1
    v = ""
    len = string.len(str);
    --ngx.say(len)
    l = string.len(r);
    for i=1,len do
        if (c == l+1) 
        then
          c=1;
        end
        b1 = string.byte(string.sub(str,i,i))
        b2 = string.byte(string.sub(r,c,c))
        --ngx.say(b1)
        --ngx.say(b2)
        box = bit.bxor(b1,b2)
        --if box > 10 then
            chars = string.char(box)
        --else
        --    chars = ""
        --end
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

function Split(str, delim, maxNb)
    if string.find(str, delim) == nil then
        return { str }
    end 
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit   
    end 
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    if nb ~= maxNb then
        result[nb+1] = string.sub(str, lastPos)
    end
    return result
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
if  ngx.var.arg_dvid ~= nil and string.len(ngx.var.arg_dvid) > 2 then
  device_id = ngx.var.arg_dvid
else
  device_id = ngx.var.cookie___utrace
end


--sort args
local tab = {}
local uri_args = ngx.req.get_uri_args()  
if not device_id then
 if uri_args['ua'] ~=nil and uri_args['ua'] ~="" then
  device_id =  ngx.md5(ngx.unescape_uri(uri_args['ip']) ..ngx.unescape_uri( uri_args['ua']));
 else
  device_id =  ngx.md5(ngx.var.remote_addr .. ngx.var.http_user_agent);
 end
 ngx.header['Set-Cookie'] = {'__utrace=' .. device_id .. '; path=/;Expires='..ngx.http_time( ngx.time() + 864000000 )..';httponly'}
end
local adPars = {"position","id","wid","channel","dvtype","uid","type","p","ua"}
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
    ngx.say("sErr")
    ngx.exit(403)
end
-- verify sig end
local uid = ngx.var.arg_uid or ngx.var.cookie_uid
uid = tonumber(uid)
local uidType = type(uid)
if uidType ~= "number" then
  uid = 0
end
-- loop print adlog
local ids = Split(ngx.unescape_uri(uri_args["id"]),"|")
local wids = Split(ngx.unescape_uri(uri_args["wid"]),"|")

for k,v in pairs(ids) do
   uri_args["i"] = string.gsub(uri_args["i"], "-" , "@@")
   newArgs = string.gsub(newArgs, "-" , "@@")
   local logStr = string.gsub(ngx.unescape_uri(newArgs), ngx.unescape_uri(uri_args["id"]) , v)
   logStr = string.gsub(logStr, ngx.unescape_uri(uri_args["wid"]) , wids[k])
   if uri_args["dvid"]== nil then
     logStr = logStr.."&dvid="..device_id
   else
     uri_args["dvid"] = string.gsub(uri_args["dvid"], "-" , "@@")
     logStr = string.gsub(logStr, "dvid="..uri_args["dvid"] , "dvid="..device_id)
   end 
   if uri_args["i"]~= nil and string.len(uri_args["i"]) > 2 then
     logStr = string.gsub(logStr, "i="..uri_args["i"] , "i="..decrypt(string.gsub(uri_args["i"], "@@" , "-"), CRYPT_KEY, true))
   end
   if uri_args["ip"] == nil or uri_args["ip"] =="" then
	ipStr = "&ip="..ngx.var.remote_addr	
   else
	ipStr = "&ip="..uri_args["ip"]
   end  
   logStr = string.gsub(logStr, "@@" , "-")
   logStr = string.gsub(logStr, "｜" , "_")
   logStr = string.gsub(logStr, "•" , "#")
   ngx.location.capture('/i-adlog?'..logStr..ipStr)
end
