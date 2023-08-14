package("dawn")
    set_homepage("https://dawn.googlesource.com/dawn")
    set_description("Dawn (formerly NXT) is an open-source and cross-platform implementation of the work-in-progress WebGPU standard. It exposes a C/C++ API that maps almost one-to-one to the WebGPU IDL and can be managed as part of a larger system such as a Web browser.")
    set_license("Apache-2.0")

    add_urls("https://dawn.googlesource.com/dawn.git")
    add_versions("2023.07.03", "chromium/5869")

    add_deps("cmake", "python", {private = true})
    if is_plat("linux", "wasm") then
        add_deps("libx11", "libxext", "libxinerama", "libxcursor", "libxrender", "libxrandr")
    end

    add_links("dawncpp", "dawn_utils", "dawn_native", "dawn_platform", "dawn_wire", "dawn_common", "dawn_proc", "dawncpp_headers", "dawn_headers")

    on_download(function (package, opt)
        import("lib.detect.find_tool")
        local git = assert(find_tool("git"), "git not found!")
        os.mkdir(opt.sourcedir)
        os.cd(opt.sourcedir)
        os.vrunv(git.program, {"init"})
        local revision = package:revision(opt.url_alias) or package:tag() or package:commit() or package:version_str()
        os.vrunv(git.program, {"config", "core.longpaths", "true"})
        os.vrunv(git.program, {"fetch", "--depth=1", opt.url, revision})
        os.vrunv(git.program, {"reset", "--hard", "FETCH_HEAD"})
        os.vrunv(git.program, {"clean", "-dfx"})
    end)

    on_install(function (package)
        -- Jinja2 is required to build dawn
        os.vrunv("python3", {"-m", "pip", "install", "-U", "pip"})
        os.vrunv("python3", {"-m", "pip", "install", "-U", "Jinja2"})

        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))

        table.insert(configs, "-DDAWN_FETCH_DEPENDENCIES=ON")

	    table.insert(configs, "-DDAWN_ENABLE_D3D11=OFF")
	    table.insert(configs, "-DDAWN_ENABLE_D3D12=OFF")
	    table.insert(configs, "-DDAWN_ENABLE_NULL=OFF")
	    table.insert(configs, "-DDAWN_ENABLE_DESKTOP_GL=OFF")
	    table.insert(configs, "-DDAWN_ENABLE_OPENGLES=OFF")
	    table.insert(configs, "-DTINT_BUILD_SPV_READER=OFF")

        if package:is_plat("macosx", "iphoneos") then
            table.insert(configs, "-DDAWN_ENABLE_METAL=ON")
            table.insert(configs, "-DDAWN_ENABLE_VULKAN=OFF")
        else
            table.insert(configs, "-DDAWN_ENABLE_METAL=OFF")
            table.insert(configs, "-DDAWN_ENABLE_VULKAN=ON")
        end

	    -- Disable unneeded parts
        table.insert(configs, "-DDAWN_BUILD_SAMPLES=OFF")
        table.insert(configs, "-DTINT_BUILD_TINT=OFF")
        table.insert(configs, "-DTINT_BUILD_SAMPLES=OFF")
        table.insert(configs, "-DTINT_BUILD_DOCS=OFF")
        table.insert(configs, "-DTINT_BUILD_TESTS=OFF")
        table.insert(configs, "-DTINT_BUILD_FUZZERS=OFF")
        table.insert(configs, "-DTINT_BUILD_SPIRV_TOOLS_FUZZER=OFF")
        table.insert(configs, "-DTINT_BUILD_AST_FUZZER=OFF")
        table.insert(configs, "-DTINT_BUILD_REGEX_FUZZER=OFF")
        table.insert(configs, "-DTINT_BUILD_BENCHMARKS=OFF")
        table.insert(configs, "-DTINT_BUILD_TESTS=OFF")
        table.insert(configs, "-DTINT_BUILD_AS_OTHER_OS=OFF")
        table.insert(configs, "-DTINT_BUILD_REMOTE_COMPILE=OFF")

        import("package.tools.cmake").build(package, configs)
        
        local buildir = package:buildir()

        os.vcp(buildir .. "/gen/include/dawn", package:installdir("include"))
        os.vcp(buildir .. "/src/dawn/**/*.dll", package:installdir("bin"))
        os.vcp(buildir .. "/src/dawn/**/*.lib", package:installdir("lib"))
    end)

    on_test(function (package)
        assert(package:has_cfuncs("wgpuCreateInstance", {includes = "dawn/webgpu.h"}))
    end)
