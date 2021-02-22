package("libuvc")
    set_homepage("https://ken.tossell.net/libuvc")
    set_description("A cross-platform library for USB video devices")
    set_license("BSD")

    set_urls("https://github.com/libuvc/libuvc.git")

    add_deps("cmake", "libusb")

    on_install("windows", "linux", "macosx", function (package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        import("package.tools.cmake").install(package, configs, {packagedeps={"libusb"}})
    end)

    on_test(function (package)
        assert(package:has_cfuncs("uvc_init", {includes = "libuvc/libuvc.h"}))
    end)
