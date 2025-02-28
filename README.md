<p align="center">
  <img src="https://github.com/user-attachments/assets/ff2ed207-c95e-45c3-831f-04a32675dbb5?size=32" alt="Banner Image" />
</p>
<pre align="center">
                                _            
  /\  /\ ___  _ __  ___  _   _ | |  ___  ___ 
 / /_/ // _ \| '__|/ __|| | | || | / _ \/ __|
/ __  /|  __/| |  | (__ | |_| || ||  __/\__ \
\/ /_/  \___||_|   \___| \__,_||_| \___||___/
</pre>
<p align="center">
  <img src="https://img.shields.io/github/stars/zeusssz/hercules-obfuscator?style=flat-square" alt="Stars" />
  <img src="https://img.shields.io/github/forks/zeusssz/hercules-obfuscator?style=flat-square" alt="Forks" />
  <img src="https://img.shields.io/github/issues/zeusssz/hercules-obfuscator?style=flat-square" alt="Issues" />
  <img src="https://img.shields.io/github/license/zeusssz/hercules-obfuscator?style=flat-square" alt="License" />
  <img src="https://img.shields.io/github/last-commit/zeusssz/hercules-obfuscator?style=flat-square" alt="Last Commit" />
  <br>
<a href="https://discord.com/oauth2/authorize?client_id=1293608330123804682">
 <img src="https://img.shields.io/badge/Add%20Bot-black?style=plastic&logo=discord&logoColor=rgb(255%2C%20255%2C%20255)" alt="Bot Invite">
</a>
<a href="https://top.gg/bot/1293608330123804682">
  <img src="https://top.gg/api/widget/servers/1293608330123804682.svg" alt="TopGG" />
</a>
<a href="https://github.com/Serpensin/DiscordBots-Hercules">
<img src="https://img.shields.io/badge/Discord%20Bot%20Repo-5865F2" alt="Bot Repo"/>
</a>
</p>

---
**Hercules** is a powerful Lua obfuscator designed to make your Lua code _nearly_ impossible to reverse-engineer. With multiple layers of advanced obfuscation techniques, Hercules ensures your scripts are secure from prying eyes.
<br>
<br>
If you decide to use/fork Hercules, please do **star it** to show support. It helps out a ton!
<br>

Contact either `zeusssz_` on Discord for queries, or join the [Discord (currently deleted)](https://discord.gg/7PnSq7HuJN), to use the **Herucles Bot**.
<br>

>[!CAUTION]
Obfuscation is not a foolproof method for protecting your code! Always consider additional security measures depending on your use case.

>[!NOTE]
Hercules is very much still in development and may not be the best yet, but we are committed to making it one of the best. Hercules is currently on version: `1.6`
---

## Features

- **String Encoding:** Transform strings into seemingly indecipherable formats using an advanced Caesar Cipher, making reverse engineering a daunting task.

- **Variable Renaming:** Elevates your code's security by replacing original variable names with a unique set of randomly generated identifiers, effectively masking their true intent.

- **Control Flow Obfuscation:** Introduces intricate, deceptive control flow structures to mislead static analysis tools, ensuring your logic remains obscured from prying eyes.

- **Garbage Code Insertion:** Strategically inject meaningless code snippets that bloat your scripts, complicating the analysis and deterring attackers.

- **Bytecode Encoding:** Seamlessly convert critical sections of your script into bytecode, adding an additional layer of complexity that hinders comprehension.

- **Function Inlining:** Enhances obfuscation by embedding function bodies directly into their calls, effectively disguising the original flow and logic of the code.

- **Opaque Predicates:** Utilizes constructed conditions that always evaluate to true or false, creating confusion about the actual functionality of your code.

- **Dynamic Code Generator:** Generates code blocks dynamically from the script itself, complicating static analysis and enhancing security.

- **String to Expressions:** Transform string literals into complex mathematical expressions, making it nearly impossible to deduce their original meaning.

- **Virtual Machinery:** Employs a virtual machine environment to execute obfuscated code, adding a layer of execution complexity that challenges traditional analysis techniques.

- **Wrap In Function:** Encapsulates entire scripts within a function, further obscuring the code's entry points and enhancing overall security.

>[!TIP]
>You can customize your obfuscation settings through the `config.lua` file.
---
## Installation

>[!IMPORTANT]
>It is recommended to use the `Lua 5.4` compiler to run Hercules

1. Clone this repository (alternatively, install the ZIP file):
    ```bash
    git clone https://github.com/zeusssz/hercules-obfuscator.git
    cd hercules-obfuscator/src
    ```

2. Run the obfuscator:
    ```bash
    lua hercules.lua path/to/your/script.lua
    ```
>[!NOTE]
>Ensure you are in the working directory of `hercules.lua`, i.e., `src` by default.

---

## Usage

To obfuscate a Lua script using Hercules, simply run:

```bash
lua hercules.lua path/to/your/script.lua
```

This will generate an obfuscated version of the script in the same directory, with the filename `*_obfuscated.lua`.

## Example

```bash
lua hercules.lua my_script.lua
```

Output:
`my_script_obfuscated.lua` – the obfuscated version of your script.
<br>
<br>

---
Original Script : `file.lua`
```lua
-- Function to print a greeting message
function Greet(name)
    print("Hello, " .. name .. "!")
end

-- Function to add two numbers
function Add(a, b)
    return a + b
end

-- Function to test a basic conditional statement
function CheckNumber(num)
    if num > 0 then
        print(num .. " is positive.")
    elseif num < 0 then
        print(num .. " is negative.")
    else
        print(num .. " is zero.")
    end
end

Greet("You")

local sum = Add(5, 10)
print("The sum of 5 and 10 is: " .. sum)

CheckNumber(5)   -- Output: 5 is positive.
CheckNumber(-3)  -- Output: -3 is negative.
CheckNumber(0)   -- Output: 0 is zero.
```
<br>

Obfuscated Script : `file_obfuscated.lua` (obfuscation was done under `Hercules v1.6.1.1`)
```lua
--[Obfuscated by Hercules v1.6 | discord.gg/Hx6RuYs8Ku (server deleted)]
return (function(...) local LULvKZwws,VFNgypmnr,SgJhiuXMa,KYWIsgYa,CbUhWnJMFL,OIJEOabg,VwkgXDdwyt,UhXcNKJBqteo,EeUiNBYECZl LULvKZwws=ipairs;VFNgypmnr=pairs;SgJhiuXMa=math.floor;KYWIsgYa=math.ldexp;CbUhWnJMFL=string.byte;OIJEOabg=string.char;VwkgXDdwyt=string.sub;UhXcNKJBqteo=table.concat;EeUiNBYECZl=table.unpack;hercules,v1,alpha,__,TNSUKtZeTLP="Protected By Hercules V1.6",function()end,true,1,0 local LuaFunc,WrapState,BcToState,gqnneaRQwArE;local IqYTmXOm=50 local JKIQaXlYSHN=select;local function DodtdDeP(TNSUKtZeTLP)return{}end;local XfSoGBtLlOKa=unpack or table.unpack local function Pack(...)return{gLOBLJrAz=JKIQaXlYSHN("#",...),...}end local function hJBjxXlnZ(nlRejAWSOC,RucRnBLVH,yLLLinqfaiEK,OepGTTbBc,EpFtYUUHXazw)for i=TNSUKtZeTLP,yLLLinqfaiEK - RucRnBLVH do EpFtYUUHXazw[OepGTTbBc+i]=nlRejAWSOC[RucRnBLVH+i]end end local function hnpgDrCljfw(VfHqDHlKZwv,qgAfPPbKrX)local kWbSKXNM=TNSUKtZeTLP local xXYuVpLPFoeT=__ while VfHqDHlKZwv>TNSUKtZeTLP and qgAfPPbKrX>TNSUKtZeTLP do if(VfHqDHlKZwv % 2==__)and(qgAfPPbKrX % 2==__)then kWbSKXNM=kWbSKXNM+xXYuVpLPFoeT end xXYuVpLPFoeT=xXYuVpLPFoeT*2 VfHqDHlKZwv=SgJhiuXMa(VfHqDHlKZwv/2)qgAfPPbKrX=SgJhiuXMa(qgAfPPbKrX/2)end return kWbSKXNM end local function SvrpWBsRsv(DQlCEeYLP,gLOBLJrAz)return DQlCEeYLP*2^gLOBLJrAz end local function kzAAZtcC(DQlCEeYLP,gLOBLJrAz)return SgJhiuXMa(DQlCEeYLP/2^gLOBLJrAz)end local function GRPqeOkD(VfHqDHlKZwv,qgAfPPbKrX)local kWbSKXNM=TNSUKtZeTLP local BQzrjiyzAmq=__ while VfHqDHlKZwv>TNSUKtZeTLP or qgAfPPbKrX>TNSUKtZeTLP do local dwkhwNXcleD=VfHqDHlKZwv % 2 local ugsLuMhKX=qgAfPPbKrX % 2 if dwkhwNXcleD==__ or ugsLuMhKX==__ then kWbSKXNM=kWbSKXNM+BQzrjiyzAmq end VfHqDHlKZwv=SgJhiuXMa(VfHqDHlKZwv/2)qgAfPPbKrX=SgJhiuXMa(qgAfPPbKrX/2)BQzrjiyzAmq=BQzrjiyzAmq*2 end return kWbSKXNM end local function FEGbdJFRbwIz(OesjstyO,mLiKyMpC)for i,uv in VFNgypmnr(OesjstyO)do if uv.mLiKyMpC>=mLiKyMpC then uv.m=uv.M[uv.mLiKyMpC];uv.M=uv;uv.mLiKyMpC="m" OesjstyO[i]=nil;end;end;end;local function cyTGqQECKrTi(OesjstyO,mLiKyMpC,EeoiWLMB)local nbLykzNc=OesjstyO[mLiKyMpC]if not nbLykzNc then nbLykzNc={mLiKyMpC=mLiKyMpC,M=EeoiWLMB}OesjstyO[mLiKyMpC]=nbLykzNc;end;return nbLykzNc;end;function sOuJicZHSj(mqVUGYpUKWb,rpYASbzNWG)local tpeONQMgfH,uXPZIEmiBGO=#rpYASbzNWG,{}local dEJladwwXuKY={}for i=1,tpeONQMgfH do dEJladwwXuKY[rpYASbzNWG:sub(i,i)]=i - 1 end for encoded_char in mqVUGYpUKWb:gmatch("[^x]+")do local gLOBLJrAz=0 for i=1,#encoded_char do gLOBLJrAz=gLOBLJrAz*tpeONQMgfH+dEJladwwXuKY[encoded_char:sub(i,i)]end uXPZIEmiBGO[#uXPZIEmiBGO+1]=OIJEOabg(gLOBLJrAz)end mqVUGYpUKWb=UhXcNKJBqteo(uXPZIEmiBGO)local icWdwWaakmqT=__ local function XdYFTRMqSp()local IHtOWLERC=CbUhWnJMFL(mqVUGYpUKWb,icWdwWaakmqT,icWdwWaakmqT)icWdwWaakmqT=icWdwWaakmqT+__ return IHtOWLERC;end;local function HiFfXRcqI()local NaaVlyzja,fVgLkeUU=CbUhWnJMFL(mqVUGYpUKWb,icWdwWaakmqT,icWdwWaakmqT+2)icWdwWaakmqT=icWdwWaakmqT+2;return(fVgLkeUU*256)+NaaVlyzja;end;local function MVQmlaxU()local NaaVlyzja,fVgLkeUU,IXKWOHHcMobk,DEtYJbMFZZ=CbUhWnJMFL(mqVUGYpUKWb,icWdwWaakmqT,icWdwWaakmqT+3)icWdwWaakmqT=icWdwWaakmqT+4;return(DEtYJbMFZZ*16777216)+(IXKWOHHcMobk*65536)+(fVgLkeUU*256)+NaaVlyzja;end;function gqnneaRQwArE()local KwYtejSsu={gLOBLJrAz=XdYFTRMqSp(),c=XdYFTRMqSp(),d=XdYFTRMqSp(),DQlCEeYLP={},D={},fddFqEuOjbyE={}}for i=__,MVQmlaxU()do local dZRhgqxbnAh=MVQmlaxU()local TuemBXJL=XdYFTRMqSp()local UimNsHqv=XdYFTRMqSp()local kUQtxTEsiOU={m=dZRhgqxbnAh,S=TuemBXJL,A=HiFfXRcqI()}local cJVnnTAbbOJt={qgAfPPbKrX=XdYFTRMqSp(),c=XdYFTRMqSp()}if(UimNsHqv==__)then kUQtxTEsiOU.OesjstyO=HiFfXRcqI()kUQtxTEsiOU.C=HiFfXRcqI()kUQtxTEsiOU.s=cJVnnTAbbOJt.qgAfPPbKrX==__ and kUQtxTEsiOU.OesjstyO>0xFF kUQtxTEsiOU.VfHqDHlKZwv=cJVnnTAbbOJt.c==__ and kUQtxTEsiOU.C>0xFF elseif(UimNsHqv==2)then kUQtxTEsiOU.F=MVQmlaxU()kUQtxTEsiOU.g=cJVnnTAbbOJt.qgAfPPbKrX==__ elseif(UimNsHqv==3)then kUQtxTEsiOU.f=MVQmlaxU()- 131071 end;KwYtejSsu.DQlCEeYLP[i]=kUQtxTEsiOU;end;for i=__,MVQmlaxU()do local UimNsHqv=XdYFTRMqSp()if(UimNsHqv==__)then KwYtejSsu.D[i - __]=(XdYFTRMqSp()~=TNSUKtZeTLP)elseif(UimNsHqv==3)then KwYtejSsu.D[i - __]=(function()local NVZSUcrb=MVQmlaxU()local zAtREAZeRT=MVQmlaxU()local gWtsuqhSy=__ local jinIUfAEjfmc=GRPqeOkD(SvrpWBsRsv(hnpgDrCljfw(zAtREAZeRT,0xFFFFF),32),NVZSUcrb);local RbIuSjGnMS=hnpgDrCljfw(kzAAZtcC(zAtREAZeRT,20),0x7FF)local yyaOzQeqUZM=(-__)^kzAAZtcC(zAtREAZeRT,31)if RbIuSjGnMS==TNSUKtZeTLP then if jinIUfAEjfmc==TNSUKtZeTLP then return yyaOzQeqUZM*TNSUKtZeTLP else RbIuSjGnMS=__ gWtsuqhSy=TNSUKtZeTLP end;elseif RbIuSjGnMS==2047 then if jinIUfAEjfmc==TNSUKtZeTLP then return yyaOzQeqUZM*(__/TNSUKtZeTLP)else return yyaOzQeqUZM*(TNSUKtZeTLP/TNSUKtZeTLP)end;end;return KYWIsgYa(yyaOzQeqUZM,RbIuSjGnMS - 1023)*(gWtsuqhSy+(jinIUfAEjfmc/(2^52)))end)()elseif(UimNsHqv==4)then KwYtejSsu.D[i - __]=(function()local chOPLSyU;local kIKgGQJboPUP=MVQmlaxU();if(kIKgGQJboPUP==TNSUKtZeTLP)then return;end;chOPLSyU=VwkgXDdwyt(mqVUGYpUKWb,icWdwWaakmqT,icWdwWaakmqT+kIKgGQJboPUP - __);icWdwWaakmqT=icWdwWaakmqT+kIKgGQJboPUP return chOPLSyU;end)()end end;for i=__,MVQmlaxU()do KwYtejSsu.fddFqEuOjbyE[i - __]=gqnneaRQwArE()end for TNSUKtZeTLP,v in LULvKZwws(KwYtejSsu.DQlCEeYLP)do if v.g then v.D=KwYtejSsu.D[v.F]else if v.s then v.A=KwYtejSsu.D[v.OesjstyO - 256]end;if v.VfHqDHlKZwv then v.C=KwYtejSsu.D[v.C - 256]end;end;end return KwYtejSsu end;return gqnneaRQwArE()end;function AMNSCtLhhZsb(GdEgXOiyeBK,GsyXGZBt,gLOBLJrAz)local DQlCEeYLP=GdEgXOiyeBK.DQlCEeYLP;local fddFqEuOjbyE=GdEgXOiyeBK.Z;local v=GdEgXOiyeBK.v;local wtgyutAm=-__;local NBIypScaTJj={}local EeoiWLMB=GdEgXOiyeBK.EeoiWLMB;local z=GdEgXOiyeBK.z;while alpha do local kUQtxTEsiOU=DQlCEeYLP[z]local S=kUQtxTEsiOU.S;z=z+__;if(S==1)then EeoiWLMB[kUQtxTEsiOU.A]=kUQtxTEsiOU.D elseif(S==2)then EeoiWLMB[kUQtxTEsiOU.A]=kUQtxTEsiOU.OesjstyO~=0 if kUQtxTEsiOU.C~=0 then z=z+1 end;elseif(S==4)then local edmCIHmZj=gLOBLJrAz[kUQtxTEsiOU.OesjstyO]EeoiWLMB[kUQtxTEsiOU.A]=edmCIHmZj.M[edmCIHmZj.mLiKyMpC]elseif(S==5)then EeoiWLMB[kUQtxTEsiOU.A]=GsyXGZBt[kUQtxTEsiOU.D]elseif(S==6)then local mLiKyMpC if kUQtxTEsiOU.VfHqDHlKZwv then mLiKyMpC=kUQtxTEsiOU.C;else mLiKyMpC=EeoiWLMB[kUQtxTEsiOU.C]end EeoiWLMB[kUQtxTEsiOU.A]=EeoiWLMB[kUQtxTEsiOU.OesjstyO][mLiKyMpC]elseif(S==7)then GsyXGZBt[kUQtxTEsiOU.D]=EeoiWLMB[kUQtxTEsiOU.A]elseif(S==0)then EeoiWLMB[kUQtxTEsiOU.A]=EeoiWLMB[kUQtxTEsiOU.OesjstyO];elseif(S==21)then local OesjstyO,C=kUQtxTEsiOU.OesjstyO,kUQtxTEsiOU.C;local WDtyZfbaTV,chOPLSyU=pcall(table.concat,EeoiWLMB,"",OesjstyO,C)if not WDtyZfbaTV then chOPLSyU=EeoiWLMB[OesjstyO]or "" for i=OesjstyO+1,C do chOPLSyU=chOPLSyU ..(EeoiWLMB[i]or EeoiWLMB[i - 1])end;end;EeoiWLMB[kUQtxTEsiOU.A]=chOPLSyU;elseif(S==22)then z=z+kUQtxTEsiOU.f elseif(S==23)then local Lhs,Rhs;if kUQtxTEsiOU.s then Lhs=kUQtxTEsiOU.A else Lhs=EeoiWLMB[kUQtxTEsiOU.OesjstyO]end if kUQtxTEsiOU.VfHqDHlKZwv then Rhs=kUQtxTEsiOU.C else Rhs=EeoiWLMB[kUQtxTEsiOU.C]end if(Lhs==Rhs)==(kUQtxTEsiOU.A~=0)then z=z+DQlCEeYLP[z].f end;z=z+1 elseif(S==24)then local Lhs,Rhs;if kUQtxTEsiOU.s then Lhs=kUQtxTEsiOU.A else Lhs=EeoiWLMB[kUQtxTEsiOU.OesjstyO]end if kUQtxTEsiOU.VfHqDHlKZwv then Rhs=kUQtxTEsiOU.C else Rhs=EeoiWLMB[kUQtxTEsiOU.C]end if(Lhs<Rhs)==(kUQtxTEsiOU.A~=0)then z=z+DQlCEeYLP[z].f end;z=z+1 elseif(S==26)then if(not EeoiWLMB[kUQtxTEsiOU.A])~=(kUQtxTEsiOU.C~=0)then z=z+DQlCEeYLP[z].f end z=z+1 elseif(S==12)then local Lhs,Rhs;if kUQtxTEsiOU.s then Lhs=kUQtxTEsiOU.A else Lhs=EeoiWLMB[kUQtxTEsiOU.OesjstyO]end if kUQtxTEsiOU.VfHqDHlKZwv then Rhs=kUQtxTEsiOU.C else Rhs=EeoiWLMB[kUQtxTEsiOU.C]end EeoiWLMB[kUQtxTEsiOU.A]=Lhs+Rhs elseif(S==28)then local A=kUQtxTEsiOU.A;local OesjstyO=kUQtxTEsiOU.OesjstyO;local C=kUQtxTEsiOU.C;local Params;if OesjstyO==0 then Params=wtgyutAm - A;else Params=OesjstyO - 1;end;local uAVYHNBIh=Pack(EeoiWLMB[A](XfSoGBtLlOKa(EeoiWLMB,A+1,A+Params)))local NUBNQhpF=uAVYHNBIh.gLOBLJrAz;if C==0 then wtgyutAm=A+NUBNQhpF - 1;else NUBNQhpF=C - 1;end;hJBjxXlnZ(uAVYHNBIh,1,NUBNQhpF,A,EeoiWLMB)elseif(S==36)then local nILfDpCJQ=fddFqEuOjbyE[kUQtxTEsiOU.F]local zMTdHzCGAf=nILfDpCJQ.gLOBLJrAz;local UvB;if zMTdHzCGAf~=0 then UvB=DodtdDeP(zMTdHzCGAf - 1)for i=1,zMTdHzCGAf do local swSvMNosKy=DQlCEeYLP[z+i - 1]if(swSvMNosKy.S==0)then UvB[i - 1]=cyTGqQECKrTi(NBIypScaTJj,swSvMNosKy.OesjstyO,EeoiWLMB)elseif(swSvMNosKy.S==4)then UvB[i - 1]=gLOBLJrAz[swSvMNosKy.OesjstyO]end;end;z=z+zMTdHzCGAf end;EeoiWLMB[kUQtxTEsiOU.A]=fXJlVDEVSMfK(nILfDpCJQ,GsyXGZBt,UvB)elseif(S==30)then local A=kUQtxTEsiOU.A;local OesjstyO=kUQtxTEsiOU.OesjstyO;local qgAfPPbKrX;if OesjstyO==0 then qgAfPPbKrX=wtgyutAm - A+1;else qgAfPPbKrX=OesjstyO - 1;end;FEGbdJFRbwIz(NBIypScaTJj,0)return XfSoGBtLlOKa(EeoiWLMB,A,A+qgAfPPbKrX - 1)end GdEgXOiyeBK.z=z;end;end;function fXJlVDEVSMfK(fddFqEuOjbyE,GsyXGZBt,wOAbslmL)local function Wrapped(...)local HHPcDUBdCRr=Pack(...)local EeoiWLMB=DodtdDeP(fddFqEuOjbyE.d)local v={qgAfPPbKrX=TNSUKtZeTLP,OesjstyO={}}hJBjxXlnZ(HHPcDUBdCRr,__,fddFqEuOjbyE.c,TNSUKtZeTLP,EeoiWLMB)if(fddFqEuOjbyE.c<HHPcDUBdCRr.gLOBLJrAz)then local PEAuPJIp=fddFqEuOjbyE.c+__ local qgAfPPbKrX=HHPcDUBdCRr.gLOBLJrAz - fddFqEuOjbyE.c;v.qgAfPPbKrX=qgAfPPbKrX;hJBjxXlnZ(HHPcDUBdCRr,PEAuPJIp,PEAuPJIp+qgAfPPbKrX - __,__,v.OesjstyO)end;local GdEgXOiyeBK={v=v,EeoiWLMB=EeoiWLMB,DQlCEeYLP=fddFqEuOjbyE.DQlCEeYLP,Z=fddFqEuOjbyE.fddFqEuOjbyE,z=__}return AMNSCtLhhZsb(GdEgXOiyeBK,GsyXGZBt,wOAbslmL)end;return Wrapped;end;fXJlVDEVSMfK(sOuJicZHSj("\62\120\62\120\88\120\85\120\62\120\62\120\62\120\95\120\62\120\62\120\62\120\95\120\42\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\123\120\42\62\120\62\120\62\120\123\120\42\120\62\120\62\120\62\120\62\120\62\120\62\120\42\120\62\120\91\120\95\62\120\95\120\95\62\120\91\120\51\120\62\120\62\120\62\120\62\120\63\120\62\120\95\120\62\120\42\88\120\62\120\62\120\62\120\88\120\95\120\42\120\62\120\42\120\62\120\62\120\62\120\62\120\62\120\42\89\120\42\62\120\51\62\120\62\120\89\120\42\120\42\120\62\120\62\120\42\120\42\120\62\120\42\120\42\120\95\42\120\95\62\120\62\120\62\120\42\120\95\120\95\120\62\120\42\120\62\120\95\120\62\120\62\120\62\120\51\42\120\51\62\120\62\120\62\120\42\120\95\120\51\120\62\120\42\120\62\120\51\120\62\120\62\120\62\120\42\53\120\95\62\120\95\62\120\42\120\53\120\42\120\42\120\62\120\62\120\62\120\51\120\62\120\95\120\62\120\61\120\95\62\120\51\62\120\62\120\61\120\42\120\62\120\62\120\42\120\42\120\42\120\62\120\95\120\42\120\91\120\42\62\120\62\120\95\62\120\91\120\51\120\62\120\62\120\62\120\62\120\42\120\62\120\95\120\62\120\42\42\120\62\120\42\120\62\120\42\120\95\120\42\120\62\120\42\120\62\120\82\120\62\120\62\120\62\120\91\120\62\120\51\41\120\42\46\120\91\120\51\120\62\120\62\120\62\120\62\120\51\84\120\51\46\120\42\120\62\120\95\120\62\120\95\62\120\62\120\95\120\42\120\62\120\62\120\62\120\62\120\42\120\62\120\62\120\62\120\91\120\95\62\120\51\78\120\42\46\120\91\120\51\120\62\120\62\120\62\120\62\120\51\76\120\51\46\120\42\120\62\120\42\58\120\62\120\62\120\62\120\58\120\95\120\42\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\42\52\120\42\62\120\42\120\62\120\52\120\95\120\42\120\62\120\42\120\62\120\88\120\62\120\62\120\62\120\42\58\120\42\62\120\62\120\62\120\58\120\95\120\42\120\62\120\62\120\62\120\42\120\62\120\62\120\62\120\42\52\120\95\62\120\42\120\62\120\52\120\95\120\42\120\62\120\42\120\62\120\89\120\62\120\62\120\62\120\42\58\120\95\62\120\62\120\62\120\58\120\95\120\42\120\62\120\62\120\62\120\95\120\62\120\62\120\62\120\42\52\120\51\62\120\42\120\62\120\52\120\95\120\42\120\62\120\42\120\62\120\52\120\62\120\62\120\62\120\42\88\120\42\62\120\42\120\62\120\88\120\95\120\42\120\62\120\42\120\62\120\88\120\62\120\62\120\62\120\95\42\120\62\120\95\120\62\120\42\120\95\120\95\120\62\120\42\120\62\120\64\120\62\120\62\120\62\120\42\53\120\42\62\120\62\120\42\120\53\120\42\120\42\120\62\120\62\120\62\120\95\120\62\120\42\120\62\120\42\88\120\95\62\120\42\120\62\120\88\120\95\120\42\120\62\120\42\120\62\120\89\120\62\120\62\120\62\120\95\42\120\42\62\120\95\120\62\120\42\120\95\120\95\120\62\120\42\120\62\120\75\120\62\120\62\120\62\120\51\42\120\95\62\120\95\120\62\120\42\120\95\120\51\120\62\120\42\120\62\120\63\120\62\120\62\120\62\120\42\53\120\95\62\120\95\62\120\42\120\53\120\42\120\42\120\62\120\62\120\62\120\51\120\62\120\95\120\62\120\95\88\120\51\62\120\95\120\62\120\88\120\95\120\95\120\62\120\42\120\62\120\60\120\62\120\62\120\62\120\51\42\120\62\120\51\120\62\120\42\120\95\120\51\120\62\120\42\120\62\120\90\120\62\120\62\120\62\120\62\120\42\120\95\62\120\62\120\62\120\42\120\82\120\62\120\62\120\62\120\42\120\62\120\62\120\62\120\51\77\120\62\120\95\42\120\42\120\77\120\42\120\51\120\62\120\62\120\62\120\51\120\62\120\82\120\62\120\95\53\120\42\62\120\62\120\42\120\53\120\42\120\95\120\62\120\62\120\62\120\95\120\62\120\42\120\62\120\95\88\120\51\62\120\42\120\62\120\88\120\95\120\95\120\62\120\42\120\62\120\52\120\62\120\62\120\62\120\51\42\120\42\62\120\95\120\62\120\42\120\95\120\51\120\62\120\42\120\62\120\75\120\62\120\62\120\62\120\95\53\120\42\62\120\62\120\42\120\53\120\42\120\95\120\62\120\62\120\62\120\95\120\62\120\42\120\62\120\95\88\120\51\62\120\42\120\62\120\88\120\95\120\95\120\62\120\42\120\62\120\52\120\62\120\62\120\62\120\51\42\120\42\62\120\51\120\62\120\42\120\95\120\51\120\62\120\42\120\62\120\67\120\62\120\62\120\62\120\95\53\120\42\62\120\62\120\42\120\53\120\42\120\95\120\62\120\62\120\62\120\95\120\62\120\42\120\62\120\95\88\120\51\62\120\42\120\62\120\88\120\95\120\95\120\62\120\42\120\62\120\52\120\62\120\62\120\62\120\51\42\120\95\62\120\62\120\62\120\42\120\95\120\51\120\62\120\42\120\62\120\95\120\62\120\62\120\62\120\95\53\120\42\62\120\62\120\42\120\53\120\42\120\95\120\62\120\62\120\62\120\95\120\62\120\42\120\62\120\44\120\62\120\95\62\120\62\120\44\120\42\120\62\120\62\120\62\120\62\120\42\120\62\120\62\120\62\120\126\120\62\120\62\120\62\120\82\120\82\120\62\120\62\120\62\120\42\59\120\42\72\120\42\84\120\42\81\120\82\120\89\120\62\120\62\120\62\120\42\76\120\42\72\120\42\66\120\42\58\120\42\36\120\42\59\120\51\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\51\120\62\120\62\120\62\120\62\120\62\120\62\120\51\47\120\46\120\51\120\62\120\62\120\62\120\62\120\62\120\42\83\120\42\49\120\42\62\120\82\120\88\120\62\120\62\120\62\120\42\52\120\42\76\120\42\125\120\42\125\120\42\84\120\82\120\51\120\62\120\62\120\62\120\42\42\120\42\58\120\42\58\120\82\120\60\120\62\120\62\120\62\120\42\51\120\42\81\120\42\125\120\42\37\120\42\70\120\42\126\120\42\33\120\42\59\120\42\57\120\42\125\120\42\76\120\82\120\51\120\62\120\62\120\62\120\42\124\120\42\36\120\42\33\120\51\120\62\120\62\120\62\120\62\120\62\120\62\120\35\120\42\62\120\51\120\62\120\62\120\62\120\62\120\62\120\62\120\58\120\42\62\120\82\120\88\120\62\120\62\120\62\120\42\47\120\42\76\120\42\69\120\42\66\120\42\84\120\82\120\61\120\62\120\62\120\62\120\42\35\120\42\81\120\42\125\120\83\120\42\71\120\42\33\120\42\59\120\83\120\42\36\120\42\93\120\83\120\33\120\83\120\42\72\120\42\66\120\42\58\120\83\120\54\120\47\120\83\120\42\69\120\42\71\120\55\120\51\120\62\120\62\120\62\120\62\120\62\120\62\120\64\120\51\62\120\51\120\62\120\62\120\62\120\62\120\42\120\88\120\52\120\62\120\62\120\62\120\42\88\120\62\120\62\120\62\120\88\120\95\120\42\120\62\120\42\120\62\120\62\120\62\120\62\120\62\120\95\42\120\42\62\120\62\120\62\120\42\120\95\120\95\120\62\120\42\120\62\120\42\120\62\120\62\120\62\120\51\62\120\62\120\62\120\62\120\62\120\42\120\51\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\42\120\95\42\120\62\120\62\120\42\120\95\120\82\120\62\120\42\120\62\120\95\120\62\120\62\120\62\120\95\77\120\62\120\42\120\42\120\77\120\42\120\95\120\62\120\62\120\62\120\95\120\62\120\82\120\62\120\42\53\120\42\62\120\62\120\42\120\53\120\42\120\42\120\62\120\62\120\62\120\95\120\62\120\42\120\62\120\44\120\62\120\95\62\120\62\120\44\120\42\120\62\120\62\120\62\120\62\120\42\120\62\120\62\120\62\120\51\120\62\120\62\120\62\120\82\120\88\120\62\120\62\120\62\120\42\47\120\42\76\120\42\69\120\42\66\120\42\84\120\82\120\89\120\62\120\62\120\62\120\42\64\120\42\125\120\42\40\120\42\40\120\42\36\120\40\120\82\120\42\120\62\120\62\120\62\120\72\120\62\120\62\120\62\120\62\120\62\120\95\120\51\120\51\120\62\120\62\120\62\120\95\90\120\42\62\120\62\120\62\120\90\120\42\120\95\120\62\120\42\120\42\120\62\120\62\120\42\120\62\120\95\44\120\62\120\62\120\42\120\44\120\42\120\95\120\62\120\62\120\62\120\95\120\62\120\62\120\62\120\44\120\62\120\95\62\120\62\120\44\120\42\120\62\120\62\120\62\120\62\120\42\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\42\120\82\120\91\120\62\120\62\120\62\120\74\120\62\120\62\120\95\62\120\74\120\42\120\62\120\62\120\42\120\42\120\62\120\42\120\62\120\62\120\91\120\42\62\120\42\120\95\62\120\91\120\51\120\62\120\62\120\62\120\62\120\88\120\62\120\95\120\62\120\42\88\120\42\62\120\62\120\62\120\88\120\95\120\42\120\62\120\42\120\62\120\42\120\62\120\62\120\62\120\95\62\120\62\120\62\120\62\120\62\120\42\120\95\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\51\42\120\95\62\120\62\120\62\120\42\120\95\120\51\120\62\120\42\120\62\120\95\120\62\120\62\120\62\120\95\77\120\51\62\120\62\120\42\120\77\120\42\120\95\120\62\120\62\120\62\120\95\120\62\120\51\120\62\120\42\53\120\42\62\120\62\120\42\120\53\120\42\120\42\120\62\120\62\120\62\120\95\120\62\120\42\120\62\120\91\120\62\120\51\120\95\62\120\91\120\51\120\62\120\62\120\62\120\62\120\90\120\62\120\95\120\62\120\74\120\62\120\42\62\120\62\120\74\120\42\120\62\120\62\120\42\120\42\120\62\120\62\120\62\120\42\120\91\120\42\62\120\42\120\95\62\120\91\120\51\120\62\120\62\120\62\120\62\120\88\120\62\120\95\120\62\120\42\88\120\42\62\120\62\120\62\120\88\120\95\120\42\120\62\120\42\120\62\120\42\120\62\120\62\120\62\120\95\62\120\62\120\62\120\62\120\62\120\42\120\95\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\51\42\120\51\62\120\62\120\62\120\42\120\95\120\51\120\62\120\42\120\62\120\51\120\62\120\62\120\62\120\95\77\120\51\62\120\62\120\42\120\77\120\42\120\95\120\62\120\62\120\62\120\95\120\62\120\51\120\62\120\42\53\120\42\62\120\62\120\42\120\53\120\42\120\42\120\62\120\62\120\62\120\95\120\62\120\42\120\62\120\91\120\62\120\42\120\95\62\120\91\120\51\120\62\120\62\120\62\120\62\120\82\120\62\120\95\120\62\120\42\88\120\42\62\120\62\120\62\120\88\120\95\120\42\120\62\120\42\120\62\120\42\120\62\120\62\120\62\120\95\62\120\62\120\62\120\62\120\62\120\42\120\95\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\51\42\120\62\120\42\120\62\120\42\120\95\120\51\120\62\120\42\120\62\120\82\120\62\120\62\120\62\120\95\77\120\51\62\120\62\120\42\120\77\120\42\120\95\120\62\120\62\120\62\120\95\120\62\120\51\120\62\120\42\53\120\42\62\120\62\120\42\120\53\120\42\120\42\120\62\120\62\120\62\120\95\120\62\120\42\120\62\120\44\120\62\120\95\62\120\62\120\44\120\42\120\62\120\62\120\62\120\62\120\42\120\62\120\62\120\62\120\88\120\62\120\62\120\62\120\51\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\62\120\82\120\88\120\62\120\62\120\62\120\42\47\120\42\76\120\42\69\120\42\66\120\42\84\120\82\120\67\120\62\120\62\120\62\120\83\120\42\69\120\42\71\120\83\120\42\47\120\42\36\120\42\71\120\42\69\120\42\84\120\42\69\120\42\73\120\42\125\120\66\120\82\120\67\120\62\120\62\120\62\120\83\120\42\69\120\42\71\120\83\120\42\66\120\42\125\120\42\96\120\42\72\120\42\84\120\42\69\120\42\73\120\42\125\120\66\120\82\120\75\120\62\120\62\120\62\120\83\120\42\69\120\42\71\120\83\120\42\55\120\42\125\120\42\76\120\42\36\120\66\120\62\120\62\120\62\120\62",">*_3RXY4@K?<ZC~8WV&D#M[=J|{O5+,0SH9%:}]`QEUF(;B$/6LGT!I21^7AN)P."),(getfenv and getfenv(0))or _ENV)() end)(...)
```
---

If you specify the overwrite option with the `--overwrite` flag, it will write back to the specified script.
<br>
You may also specify a preset using `--min`, `--mid`, or `--max`. For Example
```sh
lua src\hercules.lua my_script.lua --max
```

## Customization

You can modify or add new modules to the `modules/` directory to create additional layers of obfuscation. The `pipeline.lua` file controls the order of obfuscation steps.

---

## Project Structure

```
src/
│
├── hercules            # Main entry point (executable)
├── pipeline.lua        # Obfuscation pipeline
└── modules/            # Obfuscation modules  
```
>[!IMPORTANT]
>When adding more modules to the `modules/` directory, ensure you maintain proper order in the pipeline file, to prevent any issues, and remember to add your module to the `pipeline.lua` file.
<br>If you wish for it to be configurable, add it to the `config.lua` file, along with the necessary logic.

## Credits
VM by someone named [deoxy](https://github.com/deoxyrib0nucleid)

---
![image](https://github.com/user-attachments/assets/f0ee0abd-f4d5-4e6c-8801-07e32eec2ad9)

