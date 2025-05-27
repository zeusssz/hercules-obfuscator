local AntiTamper = {}
-- anti beautify + simple anti tamper for now
function AntiTamper.process(code)
  local anti_tamper_code = [[
do  
    local D,T,P,X,S,E,R,Pa,GM,SM,RG,RS,RE,CG,Sel,C,G=  
        debug,type,pcall,xpcall,tostring,error,rawget,pairs,  
        getmetatable,setmetatable,rawget,rawset,rawequal,collectgarbage,select,coroutine,_G  
  
    local function dbgOK()  
        if T(D)~="table" then return false end  
        for _,k in Pa{"getinfo","getlocal","getupvalue","traceback","sethook","setupvalue","getregistry"} do  
            if T(D[k])~="function" then return false end  
        end  
        return true  
    end  
    if not dbgOK() then E("Tamper Detected! Reason: Debug library incomplete") return end  
  
    local function isNative(f)  
        local i=D.getinfo(f)  
        return i and i.what=="C"  
    end  
  
    local function checkNativeFuncs()  
        local natives={  
            P,X,assert,E,print,RG,RS,RE,tonumber,S,T,  
            Sel,next,ipairs,Pa,CG,GM,SM,  
            load,loadstring,loadfile,dofile,collectgarbage,  
            D.getinfo,D.getlocal,D.getupvalue,D.sethook,D.setupvalue,D.traceback,  
            C.create,C.resume,C.yield,C.status,  
            math.abs,math.acos,math.asin,math.atan,math.ceil,math.cos,math.deg,math.exp,  
            math.floor,math.fmod,math.huge,math.log,math.max,math.min,math.modf,math.pi,  
            math.rad,math.random,math.sin,math.sqrt,math.tan,  
            os.clock,os.date,os.difftime,os.execute,os.exit,os.getenv,os.remove,  
            os.rename,os.setlocale,os.time,os.tmpname,  
            string.byte,string.char,string.dump,string.find,string.format,string.gmatch,  
            string.gsub,string.len,string.lower,string.match,string.rep,string.reverse,  
            string.sub,string.upper,  
            table.insert,table.maxn,table.remove,table.sort  
        }  
        local mts={string,table,math,os,G,package}  
        for _,t in Pa(mts) do  
            local mt=GM(t)  
            if mt then  
                for _,m in Pa{"__index","__newindex","__call","__metatable"} do  
                    local mf=mt[m]  
                    if mf and T(mf)=="function" and not isNative(mf) then  
                        return false,"Metamethod tampered: "..m  
                    end  
                end  
            end  
        end  
        for _,fn in Pa(natives) do  
            if T(fn)=="function" and not isNative(fn) then  
                return false,"Native function replaced or wrapped"  
            end  
        end  
        return true  
    end  
  
    local function isMinified(f)  
        local i=D.getinfo(f,"Sl")  
        return i and i.linedefined==i.lastlinedefined  
    end  
  
    local function scanUp(f)  
        local i=1  
        while true do  
            local n,v=D.getupvalue(f,i)  
            if not n then break end  
            if T(v)=="function" and not isMinified(v) then return false,"Suspicious upvalue: "..n end  
            i=i+1  
        end  
        return true  
    end  
  
    local function scanLocals(l)  
        local i=1  
        while true do  
            local n,v=D.getlocal(l,i)  
            if not n then break end  
            if T(v)=="function" and not isMinified(v) then return false,"Suspicious local: "..n end  
            i=i+1  
        end  
        return true  
    end  
  
    local function checkGlobals()  
        local essentials={"pcall","xpcall","type","tostring","string","table","debug","coroutine","math","os","package"}  
        for _,k in Pa(essentials) do  
            if T(G[k])~=T(_G[k]) then return false,"Global modified: "..k end  
        end  
        if package and package.loaded and T(package.loaded.debug)~="table" then  
            return false,"Package.debug modified"  
        end  
        return true  
    end  
  
    local function run()  
        local ok,r=checkNativeFuncs()  
        if not ok then return false,r end  
        ok,r=checkGlobals()  
        if not ok then return false,r end  
        for l=2,4 do  
            local i=D.getinfo(l,"f")  
            if i and i.func then  
                ok,r=scanUp(i.func)  
                if not ok then return false,r.." @lvl "..l end  
            end  
            ok,r=scanLocals(l)  
            if not ok then return false,r.." @lvl "..l end  
        end  
        return true  
    end  
  
    local ok,r=run()  
    if not ok then  
        E("Tamper Detected! Reason: "..S(r))  
        while true do E("Tamper Detected! Reason: "..S(r)) end  
    end  
end
]]
  return anti_tamper_code .. "\n" .. code
end

return AntiTamper
