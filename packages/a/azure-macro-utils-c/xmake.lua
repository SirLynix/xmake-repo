package("azure-c-shared-utility")
    set_homepage("https://github.com/Azure/azure-c-shared-utility")
    set_description("Very useful C macros for Azure")
    set_license("MIT")

    set_urls("https://github.com/Azure/macro-utils-c.git")

    add_versions("2020-12-09", "8cf59c75666c4cdffc2f672598668e6ce474c857e1be1ccebeee3edd50cbf69b")

    on_install(function (package)
        os.cp("inc/*.h", package:installdir("include/macro_utils"))
    end)

    on_test(function (package)
        assert(package:check_csnippets({test = [[
            MU_EAT_EMPTY_ARGS(EMPTY_MACRO)
        ]]}, {includes = "macro_utils/macro_utils.h"}))
    end)
