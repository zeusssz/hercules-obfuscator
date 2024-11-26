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
If you do decide to use/fork Hercules, please do **star it** to show support. It helps out a ton!
<br>

Contact either `roboxer_` or `xthrx0` on Discord for queries, or join the [Discord (currently deleted)](https://discord.gg/7PnSq7HuJN), to use the **Herucles Bot**.
<br>

>[!CAUTION]
Obfuscation is not a foolproof method for protecting your code! Always consider additional security measures depending on your use case.

>[!NOTE]
Hercules is very much still in development and may not be the best yet, but we are committed to making it one of the best. Hercules is currently on version `1.6`
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

- **Virtual Machinery:** Employs a sophisticated virtual machine environment to execute obfuscated code, adding a layer of execution complexity that challenges traditional analysis techniques.

- **Wrap In Function:** Encapsulates entire scripts within a function, further obscuring the code's entry points and enhancing overall security.

>[!TIP]
>You can customize your level of obfuscation through the `config.lua` file.
---
## Installation

### macOS and Linux

1. Clone this repository:
    ```bash
    git clone https://github.com/zeusssz/hercules-obfuscator.git
    cd hercules-obfuscator/src
    ```

2. Make the `hercules` script executable:
    ```bash
    chmod +x hercules
    ```

3. Run the obfuscator:
    ```bash
    ./hercules path/to/your/script.lua
    ```
>[!NOTE]
>Ensure you are in the working directory of the executable, i.e., `src` by default. Alternatively, you can use the Lua interpreter directly if it is added to your system PATH.

### Windows

1. Clone this repository using Git Bash or download the ZIP file and extract it.

2. Open Command Prompt or PowerShell and navigate to the `hercules-obfuscator` directory.

3. Run the obfuscator using Lua:
    ```cmd
    lua src\hercules path\to\your\script.lua
    ```
---

## Usage

To obfuscate a Lua script using Hercules, simply run:

```bash
./hercules path/to/your/script.lua  # macOS/Linux
lua src\hercules path\to\your\script.lua  # Windows
```

This will generate an obfuscated version of the script in the same directory, with the filename `*_obfuscated.lua`.

## Example

```bash
./hercules my_script.lua  # macOS/Linux
lua src\hercules my_script.lua  # Windows
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

Obfuscated Script : `file_obfuscated.lua` (except Function Inliner & Dynamic Code Generator (modules to be fixed soon))
```lua
--[Obfuscated by Hercules v1.6 | discord.gg/Hx6RuYs8Ku (server deleted)]
return (function(...) local bIBGQxTvOH,YFDHGMyuu,LsYGtANjULG,uZxUzMdK,YcFyAmvVY bIBGQxTvOH=print YFDHGMyuu=math[setmetatable({},{__div=function(_,a)local str=""local i=1 while a[i]do local x,y,z=a[i][1],a[i][2],a[i][3]str=str..str.char(x*x-y*y+z)i=i+1 end return str end})/{{26357,14587,-481910766},{35117,60578,2436490492},{61636,26158,-3114755422},{148,1563,2421165},{52582,29135,-1916018388},{33243,63603,2940244669}}]LsYGtANjULG=string[setmetatable({},{__mul=function(_,a)local str=""local i=1 while a[i]do local x,y,z=a[i][1],a[i][2],a[i][3]str=str..str.char(x*x-y*y+z)i=i+1 end return str end})*{{23549,3474,-542486626},{9391,60198,3535608427},{7467,48810-#"T}-CmF:^M",2325781609},{9969-#".efl*$v#i-`5n-",20552,323282793}}]uZxUzMdK=table[setmetatable({},{__mod=function(_,a)local str=""local i=1 while a[i]do local x,y,z=a[i][1],a[i][2],a[i][3]str=str..str.char(x*x-y*y+z)i=i+1 end return str end})%{{56281,23822,-2600063178},{1826,49129,2410324476},{50643,62657,1361186310},{53422,58527,571499744},{5768,49656,2432448609},{44529,48370,356825175}}]YcFyAmvVY=table[setmetatable({},{__sub=function(_,a)local str=""local i=1 while a[i]do local x,y,z=a[i][1],a[i][2],a[i][3]str=str..str.char(x*x-y*y+z)i=i+1 end return str end})-{{47128-#".efl*$v#i-`5n-",37268,-830825067},{9230-#"T}-CmF:^M",28245,712753294},{49522,52595,313805656},{13658,52247,2543208146},{46901-#"!-+khDmg>nFU,.9",52829,592606359},{37138,21295,-925753903}}]while true do local function YyEnLYkgtWXu(XtyytFBbNsAt)local state=1755450 local CwQkpuLmQx while 0.14395348012729 do if state==1755450 then state=2244624 CwQkpuLmQx=setmetatable({},{["__add"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})+{25725-#"b=79f3XM",38352,809511900}end end end break end local TlwsCFJqN=false while not TlwsCFJqN do if YFDHGMyuu(1123308550%18970,2595042451%47775)==(2126762620%58010)then local YMNYVnfXJCha=1554462452%27324 else TlwsCFJqN=true end end local function twUOqlyJzQK(KRpxNJGSNtfM)local state=3648422 while 0.8301097165056 do if state==3648422 then state=937278 return(KRpxNJGSNtfM>=(481194378%24410)and KRpxNJGSNtfM<=(setmetatable({},{["__div"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})/{27263,7970,-679750212}))or(KRpxNJGSNtfM>=(759251285%17310)and KRpxNJGSNtfM<=(setmetatable({},{["__sub"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})-{45111,14737,-1817823062}))or(KRpxNJGSNtfM>=(1989161131%39462)and KRpxNJGSNtfM<=(setmetatable({},{["__pow"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})^{47413,40975,-569041822}))end end end local function EBZQZBbae(aaBfTdNv,XBmsfrcA)local state=4097062 local UGSjKCvlOPPe while 0.81955814934139 do if state==1774427 then state=1587544 for i=setmetatable({},{["__concat"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})..{44887,6048,-1978264464},#aaBfTdNv do local KRpxNJGSNtfM=aaBfTdNv:byte(i)if twUOqlyJzQK(KRpxNJGSNtfM)then local GXbq4LLNNF4EO if KRpxNJGSNtfM>=(setmetatable({},{["__add"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})+{64398,58014,-781478160})and KRpxNJGSNtfM<=(24502026%8487)then GXbq4LLNNF4EO=((KRpxNJGSNtfM-(setmetatable({},{["__div"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})/{64698,59838,-605244912})-XBmsfrcA+(setmetatable({},{["__add"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})+{45660,50399,455223611}))%(1357505426%34264))+(3197583975%62983)elseif KRpxNJGSNtfM>=(159949585%54037)and KRpxNJGSNtfM<=(199150186%52079)then GXbq4LLNNF4EO=((KRpxNJGSNtfM-(setmetatable({},{["__add"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})+{13509-#"eL?^`3dz{pIr",22389,319098377})-XBmsfrcA+(setmetatable({},{["__pow"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})^{46853,20378,-1779940699}))%(96123656%6898))+(setmetatable({},{["__div"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})/{64786-#"$C8.L$DfiZN",10336,-4088967664})elseif KRpxNJGSNtfM>=(setmetatable({},{["__pow"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})^{20518,41279,1282967614})and KRpxNJGSNtfM<=(setmetatable({},{["__div"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})/{36790,20925,-915648353})then GXbq4LLNNF4EO=((KRpxNJGSNtfM-(setmetatable({},{["__pow"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})^{34868-#"bmbD4g`wO",25478,-566021300})-XBmsfrcA+(513850742%56754))%(setmetatable({},{["__div"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})/{6596,44886,1971245806}))+(setmetatable({},{["__pow"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})^{24696,36362,712302725})end YcFyAmvVY(UGSjKCvlOPPe,LsYGtANjULG(GXbq4LLNNF4EO))else YcFyAmvVY(UGSjKCvlOPPe,LsYGtANjULG(KRpxNJGSNtfM))end end else if state==4097062 then state=1774427 UGSjKCvlOPPe={}end if state==1587544 then state=420618 return uZxUzMdK(UGSjKCvlOPPe)end end end end function OgRfGltoG(JxrPOxNv)bIBGQxTvOH(EBZQZBbae(setmetatable({},{__div=function(_,a)local str=""local i=1 while a[i]do local x,y,z=a[i][1],a[i][2],a[i][3]str=str..str.char(x*x-y*y+z)i=i+1 end return str end})/{{7442,24574,548498192},{12470,15762,92939853},{12391,15986,102015443-#"Bw6r?Mh.iYCv"},{35910,14768,-1071434160},{51420,45236,-597720585},{13760,24511,411451565},{25893,35951,622026984}},-(setmetatable({},{["__mod"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})%{64008-#"$C8.L$DfiZN",38883,-2068435732}))..JxrPOxNv..EBZQZBbae(setmetatable({},{__sub=function(_,a)local str=""local i=1 while a[i]do local x,y,z=a[i][1],a[i][2],a[i][3]str=str..str.char(x*x-y*y+z)i=i+1 end return str end})-{{17462,54962,2715900033}},-(setmetatable({},{["__sub"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})-{37181,26429,502995169})))end function GhPgrqQ(a,b)return a+b end function NgpOlKRk(num)if num>(setmetatable({},{["__pow"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})^{22419,31643,498667888})then bIBGQxTvOH(num..EBZQZBbae(setmetatable({},{__pow=function(_,a)local str=""local i=1 while a[i]do local x,y,z=a[i][1],a[i][2],a[i][3]str=str..str.char(x*x-y*y+z)i=i+1 end return str end})^{{34601,33806,-54383533},{7138-#"e,Y8FcejB>::i",3735,-36815293},{63912,16449,-3814174026},{49320,50959,164357313},{26628,23058,-177378906},{10642,40293,1510273798},{49767,39809,-891997691},{58894,51991,-765439048},{31663,3152-#"@~GIIn6Hxq",-992673287},{19164,44726,1633156287},{59083,35752-#"@~GIIn6Hxq",-2213310205},{59298-#"nq}kh{x[]cBS5cX",5914,-3479498590},{21770,6051,-437318253}},-(setmetatable({},{["__div"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})/{1922,6944,586665584})))elseif num<(279039000%4700)then bIBGQxTvOH(num..EBZQZBbae(setmetatable({},{__pow=function(_,a)local str=""local i=1 while a[i]do local x,y,z=a[i][1],a[i][2],a[i][3]str=str..str.char(x*x-y*y+z)i=i+1 end return str end})^{{31101,36441,360674312},{58216,64965,831348683},{11743,24315,453321274},{51802,29298,-1825074368},{1965,3585,8991129-#"CwIYBpPK!2"},{30966-#"0qeO>7GvyAf|6E=",64862,3249114753},{38485,24209,-895019432},{31562,19517,-615246449},{4444,44465,1957387188},{45555,7078,-2025159827},{51667,44945,-649425763},{20859,19212,-65996827},{49874,13374,-2308551954}},setmetatable({},{["__concat"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})..{62769,15910,-2457905124}))else bIBGQxTvOH(num..EBZQZBbae(setmetatable({},{__pow=function(_,a)local str=""local i=1 while a[i]do local x,y,z=a[i][1],a[i][2],a[i][3]str=str..str.char(x*x-y*y+z)i=i+1 end return str end})^{{25042,16930,-340476832},{60287,29050,-2790619752},{28271,2750,-791686840},{38432,22113,-988033823},{33453,34207,51015748},{40552,44808,363292273},{48067,20740,-1880288789},{41848,19451,-1372913606},{26632,7031,-659828417}},setmetatable({},{["__add"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})+{231,14750,1091142457}))end end OgRfGltoG(EBZQZBbae(setmetatable({},{__concat=function(_,a)local str=""local i=1 while a[i]do local x,y,z=a[i][1],a[i][2],a[i][3]str=str..str.char(x*x-y*y+z)i=i+1 end return str end})..{{17662-#"7+9&e)<1JO+i;",4267,-293279825},{8255,22885,455578309},{53821,54393,61898523}},setmetatable({},{["__add"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})+{65314,61597,-314134181}))local FGbQxrTHf=GhPgrqQ(1263547181%44579,233473894%11103)bIBGQxTvOH(EBZQZBbae(setmetatable({},{__add=function(_,a)local str=""local i=1 while a[i]do local x,y,z=a[i][1],a[i][2],a[i][3]str=str..str.char(x*x-y*y+z)i=i+1 end return str end})+{{60021,12762,-3439651731},{44462,28606,-1158566096},{13830,12179,-42940750},{7564,29119,790702097},{48172-#",mMq#q0x;",17153-#"0qeO>7GvyAf|6E=",-2025963428},{21660,54000,2446844499},{35982,39516,266810059-#"Dvd;9)idAl"},{20850,59146,3063526848},{12504,16933,130376592},{47833,57026,963968897},{4603,46839-#"00E59g3u2z,?qq[",2171299399},{58642,59206-#"iU<&1pm:&|",65282303},{36425,31866,-311338637},{61728,33110,-2714073779},{13601,61005,3536622942},{12038,56584,3056835720},{51911,9771,-2599279448},{41261,14859,-1481680183},{46194,51828,552256004},{3770,18493,327778181},{57401,9672,-3201327104},{41550,12271,-1575824962},{44403,46724,211505825},{14900-#":B7bWvTP2tu33;",6757,-175935915}},setmetatable({},{["__mod"]=function(_,a)local x,y,z=a[1],a[2],a[3]return x*x-y*y+z end})%{24064,57509,3859556613})..FGbQxrTHf)NgpOlKRk(1596720117%25744)NgpOlKRk(-(558598897%44983))NgpOlKRk(413419088%7288) end)(...)
```
---

If you specify the overwrite option with the `--overwrite` flag, it will write back to the specified script.
<br>
You may also specify an alternate pipeline file using `--pipeline`, along with a file argument. For example:
```sh
lua src\hercules.lua my_script.lua --pipeline custom_pipeline.lua 
```
>[!NOTE]
>Ensure that your custom pipeline file is **in the same directory** as `hercules.lua`.

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

## Incoming Updates
GUI Update
<br>
Fixes of unreliable modules

---
![image](https://github.com/user-attachments/assets/f0ee0abd-f4d5-4e6c-8801-07e32eec2ad9)

