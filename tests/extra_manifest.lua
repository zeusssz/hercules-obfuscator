return {
    modules = {
        {
            key = "dummy_test_module",
            config_key = "dummy_test_module",
            name = "Dummy Test Module",
            module = "test_modules/dummy_module",
            enabled = true,
            bit_position = 30,
            pipeline_order = 1000,
            cli = { short = "-dtm", long = "--dummy_test_module" },
            incompatible_with = {},
            description = "Dummy module used by manifest tests",
        },
    },
}
