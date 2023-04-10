package("joltphysics")
    set_homepage("https://github.com/jrouwe/JoltPhysics")
    set_description("A multi core friendly rigid body physics and collision detection library suitable for games and VR applications.")
    set_license("MIT")

    add_urls("https://github.com/jrouwe/JoltPhysics.git")
    add_versions("v2.0.1+1", "8aef496713c398eab4621954b74433826f10d0fd")
    add_patches("v2.0.1+1", "https://github.com/jrouwe/JoltPhysics/commit/f5a5efc9c2b71c300d65f169cd6c54159b18a080.patch", "f74fd504bcc15b2b49943ba0e2405953c9e57b34dda94c7ac47463ec2f25f58d")
    add_patches("v2.0.1+1", "https://github.com/jrouwe/JoltPhysics/commit/8ba3e7c52a9255db86cd3e547f5f8f5e2788d15a.patch", "b5fb112d68d38c35d36c9b564a5eefae1bb791b1bfcca0c61f2c4e7970abfbe1")

    add_configs("cross_platform_deterministic", { description = "Turns on behavior to attempt cross platform determinism", default = false, type = "boolean" })
    add_configs("debug_renderer", { description = "Adds support to draw lines and triangles, used to be able to debug draw the state of the world", default = true, type = "boolean" })
    add_configs("double_precision", { description = "Compiles the library so that all positions are stored in doubles instead of floats. This makes larger worlds possible", default = false, type = "boolean" })
    add_configs("profile", { description = "Turns on the internal profiler", defines = "JPH_PROFILE_ENABLED"})

    if is_arch("x86", "x64", "x86_64") then
        add_configs("inst_avx", { description = "Enable AVX CPU instructions (x86/x64 only)", default = false, type = "boolean" })
        add_configs("inst_avx2", { description = "Enable AVX2 CPU instructions (x86/x64 only)", default = false, type = "boolean" })
        add_configs("inst_avx512", { description = "Enable AVX512F+AVX512VL CPU instructions (x86/x64 only)", default = false, type = "boolean" })
        add_configs("inst_f16c", { description = "Enable half float CPU instructions (x86/x64 only)", default = false, type = "boolean" })
        add_configs("inst_fmadd", { description = "Enable fused multiply add CPU instructions (x86/x64 only)", default = false, type = "boolean" })
        add_configs("inst_lzcnt", { description = "Enable the lzcnt CPU instruction (x86/x64 only)", default = false, type = "boolean" })
        add_configs("inst_sse4_1", { description = "Enable SSE4.1 CPU instructions (x86/x64 only)", default = false, type = "boolean" })
        add_configs("inst_sse4_2", { description = "Enable SSE4.2 CPU instructions (x86/x64 only)", default = false, type = "boolean" })
        add_configs("inst_tzcnt", { description = "Enable the tzcnt CPU instruction (x86/x64 only)", default = false, type = "boolean" })
    end

    -- jolt physics doesn't support dynamic link
    add_configs("shared", {description = "Build shared library.", default = false, type = "boolean", readonly = true})

    if is_plat("linux", "macosx", "iphoneos", "bsd", "wasm") then
        add_syslinks("pthread")
    end

    add_deps("cmake")

    on_load(function (package)
        if package:is_plat("windows") and not package:config("shared") then
            package:add("syslinks", "Advapi32")
        end
        if package:config("cross_platform_deterministic") then
            package:add("defines", "JPH_CROSS_PLATFORM_DETERMINISTIC")
        end
        if package:config("debug_renderer") then
            package:add("defines", "JPH_DEBUG_RENDERER")
        end
        if package:config("double_precision") then
            package:add("defines", "JPH_DOUBLE_PRECISION")
        end
    end)

    on_install("windows", "mingw", "linux", "macosx", "iphoneos", "android", "wasm", function (package)
        --[[os.cp(path.join(os.scriptdir(), "port", "xmake.lua"), "xmake.lua")
        local configs = {}
        configs.cross_platform_deterministic = package:config("cross_platform_deterministic")
        configs.double_precision = package:config("double_precision")
        if is_arch("x86", "x64", "x86_64") then
            configs.inst_avx    = package:config("inst_avx")
            configs.inst_avx2   = package:config("inst_avx2")
            configs.inst_avx512 = package:config("inst_avx512")
            configs.inst_f16c   = package:config("inst_f16c")
            configs.inst_fmadd  = package:config("inst_fmadd")
            configs.inst_lzcnt  = package:config("inst_lzcnt")
            configs.inst_sse4_1 = package:config("inst_sse4_1")
            configs.inst_sse4_2 = package:config("inst_sse4_2")
            configs.inst_tzcnt  = package:config("inst_tzcnt")
        end
        import("package.tools.xmake").install(package, configs)]]
        os.cd("Build")
        local configs = {
            "-DINTERPROCEDURAL_OPTIMIZATION=OFF",
            "-DTARGET_UNIT_TESTS=OFF",
            "-DTARGET_HELLO_WORLD=OFF",
            "-DTARGET_PERFORMANCE_TEST=OFF",
            "-DTARGET_SAMPLES=OFF",
            "-DTARGET_VIEWER=OFF",
            "-DENABLE_ALL_WARNINGS=OFF"
        }
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DCROSS_PLATFORM_DETERMINISTIC=" .. (package:config("cross_platform_deterministic") and "ON" or "OFF"))
        table.insert(configs, "-DDOUBLE_PRECISION=" .. (package:config("double_precision") and "ON" or "OFF"))
        table.insert(configs, "-DGENERATE_DEBUG_SYMBOLS=" .. (package:debug() and "ON" or "OFF"))
        table.insert(configs, "-DINTERPROCEDURAL_OPTIMIZATION=OFF")
        table.insert(configs, "-DUSE_AVX=" .. (package:config("inst_avx") and "ON" or "OFF"))
        table.insert(configs, "-DUSE_AVX2=" .. (package:config("inst_avx2") and "ON" or "OFF"))
        table.insert(configs, "-DUSE_AVX512=" .. (package:config("inst_avx512") and "ON" or "OFF"))
        table.insert(configs, "-DUSE_F16C=" .. (package:config("inst_f16c") and "ON" or "OFF"))
        table.insert(configs, "-DUSE_FMADD=" .. (package:config("inst_fmadd") and "ON" or "OFF"))
        table.insert(configs, "-DUSE_LZCNT=" .. (package:config("inst_lzcnt") and "ON" or "OFF"))
        table.insert(configs, "-DUSE_SSE4_1=" .. (package:config("inst_sse4_1") and "ON" or "OFF"))
        table.insert(configs, "-DUSE_SSE4_2=" .. (package:config("inst_sse4_2") and "ON" or "OFF"))
        table.insert(configs, "-DUSE_TZCNT=" .. (package:config("inst_tzcnt") and "ON" or "OFF"))

        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            void test() {
                JPH::RegisterDefaultAllocator();
                JPH::PhysicsSystem physics_system;
                physics_system.OptimizeBroadPhase();
            }
        ]]}, {configs = {languages = "c++17"}, includes = {"Jolt/Jolt.h", "Jolt/Physics/PhysicsSystem.h"}}))
    end)
