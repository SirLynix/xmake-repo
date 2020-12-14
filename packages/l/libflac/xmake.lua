package("libflac")

    set_homepage("https://xiph.org/flac")
    set_description("Free Lossless Audio Codec")
    set_license("BSD")

    set_urls("https://github.com/xiph/flac/archive/$(version).tar.gz",
             "https://github.com/xiph/flac.git")

    add_versions("1.3.3", "668cdeab898a7dd43cf84739f7e1f3ed6b35ece2ef9968a5c7079fe9adfe1689")
    add_patches("1.3.3", path.join(os.scriptdir(), "patches", "1.3.3", "cmake.patch"), "49baa40ab70d63e74cfc3f0cc2f13824545a618ceaeffdd51d3333d90b37fd32")

    add_deps("cmake", "libogg")

    if is_plat("linux") then
        add_syslinks("m")
    end

    on_load("windows", "mingw", function (package)
        if not package:config("shared") then
            package:add("defines", "FLAC__NO_DLL")
        end
    end)

    on_install("windows", "linux", "macosx", "iphoneos", "mingw", "android", function (package)
        local configs = {}
        table.insert(configs, "-DBUILD_CXXLIBS=OFF")
        table.insert(configs, "-DBUILD_DOCS=OFF")
        table.insert(configs, "-DBUILD_PROGRAMS=OFF")
        table.insert(configs, "-DBUILD_EXAMPLES=OFF")
        table.insert(configs, "-DBUILD_TESTING=OFF")
        table.insert(configs, "-DBUILD_UTILS=OFF")
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        table.insert(configs, "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")

        -- we pass libogg as packagedeps instead of findOgg.cmake (it does not work)
        local libogg = package:dep("libogg"):fetch()
        if libogg then
            local links = table.concat(table.wrap(libogg.links), " ")
            io.replace("CMakeLists.txt", "find_package(OGG REQUIRED)", "", {plain = true})
            io.replace("src/libFLAC/CMakeLists.txt", 
            [[
if(TARGET Ogg::ogg)
    target_link_libraries(FLAC PUBLIC Ogg::ogg)
endif()]], "target_link_libraries(FLAC PUBLIC " .. links .. ")", {plain = true})
        end
        if package:config("shared") and package:is_plat("mingw") then
            -- stack protection in shared with MinGW causes linking error
            io.replace("CMakeLists.txt", [[
    $<$<AND:$<BOOL:${HAVE_SSP_FLAG}>,$<BOOL:${ENABLE_SSP}>>:-fstack-protector>
    $<$<AND:$<BOOL:${HAVE_SSP_FLAG}>,$<BOOL:${ENABLE_SSP}>>:--param>
    $<$<AND:$<BOOL:${HAVE_SSP_FLAG}>,$<BOOL:${ENABLE_SSP}>>:ssp-buffer-size=4>]], "", {plain = true})
        end
        import("package.tools.cmake").install(package, configs, {packagedeps = "libogg"})
    end)

    on_test(function (package)
        assert(package:has_cfuncs("FLAC__format_sample_rate_is_valid", {includes = "FLAC/format.h"}))
    end)
