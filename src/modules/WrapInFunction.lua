local Wrapper = {}
function Wrapper.process(code)
return [[(function(...) ]]..code..[[ end)(...)]]
end
return Wrapper
