package("azure-c-shared-utility")
    set_homepage("https://github.com/Azure/azure-c-shared-utility")
    set_description("Azure C SDKs common code")
    set_license("MIT")

    set_urls("https://github.com/Azure/azure-c-shared-utility/archive/$(version).tar.gz",
             "https://github.com/Azure/azure-c-shared-utility.git")

    add_versions("2020-12-09", "73106554449c64aff6b068078f0eada50c4474e99945b5ceb6ea4aab9a68457f")

    add_deps("cmake")

    if is_plat("linux") then
        add_deps("libcurl", "openssl")
    end

    on_install("windows", "linux", "macosx", function (package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))

        local opt
        if package:is_plat("linux") then
            opt = {packagedeps={"libcurl", "openssl"}}
        end
        import("package.tools.cmake").install(package, configs, opt)
    end)

    on_test(function (package)
        assert(package:has_cfuncs("platform_init", {includes = "azure_c_shared_utility/platform.h"}))
    end)
