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
