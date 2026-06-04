local DummyModule = {}

function DummyModule.process(code)
    return code .. "\n_G.__hercules_dummy_module_ran = true"
end

return DummyModule
