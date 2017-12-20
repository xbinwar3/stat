ngx.header.content_type = "text/plain";
local args = string.gsub(ngx.var.args, "%%7C" , "|") 
args = string.gsub(args, "|" , "_")  
args = string.gsub(args, "｜" , "_")
args = string.gsub(args, "•" , "#")
local cc = ngx.location.capture('/i-promolog?'.. args)

