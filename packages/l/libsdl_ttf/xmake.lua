package("libsdl_ttf")
    set_homepage("https://github.com/libsdl-org/SDL_ttf/")
    set_description("Simple DirectMedia Layer text rendering library")
    set_license("zlib")

    if is_plat("mingw") and is_subhost("msys") then
        add_extsources("pacman::SDL2_ttf")
    elseif is_plat("linux") then
        add_extsources("pacman::sdl2_ttf", "apt::libsdl2-ttf-dev")
    elseif is_plat("macosx") then
        add_extsources("brew::sdl2_ttf")
    end

    add_urls("https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-$(version).zip",
             "https://github.com/libsdl-org/SDL_ttf/releases/download/release-$(version)/SDL2_ttf-$(version).zip")
    add_versions("2.20.0", "04e94fc5ecac3475ab35c1d5cf52650df691867e7e4befcc861bf982a747111a")
    add_versions("2.20.1", "18d81ab399c8e39adababe8918691830ba6e0d6448e5baa141ee0ddf87ede2dc")

    add_deps("cmake", "libsdl", "freetype")

    add_includedirs("include", "include/SDL2")

    on_install(function (package)
        local configs = {"-DSDL2TTF_SAMPLES=OFF"}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        local libsdl = package:dep("libsdl")
        if libsdl and not libsdl:is_system() then
            table.insert(configs, "-DSDL2_DIR=" .. libsdl:installdir())
            local fetchinfo = libsdl:fetch()
            if fetchinfo then
                for _, dir in ipairs(fetchinfo.includedirs or fetchinfo.sysincludedirs) do
                    if os.isfile(path.join(dir, "SDL_version.h")) then
                        table.insert(configs, "-DSDL2_INCLUDE_DIR=" .. dir)
                        break                        
                    end
                end
                for _, libfile in ipairs(fetchinfo.libfiles) do
                    if libfile:match("SDL2%..+$") or libfile:match("SDL2-static%..+$") then
                        table.insert(configs, "-DSDL2_LIBRARY=" .. libfile)
                    end
                end
            end
        end

        local freetype = package:dep("freetype")
        local opt
        if freetype and not freetype:is_system() then
            -- pass freetype ourselves to handle its dependencies properly
            io.replace("CMakeLists.txt", "set(SDL2TTF_FREETYPE ON)", "set(SDL2TTF_FREETYPE OFF)", {plain = true})

            local ldflags = {}
            opt = {
                packagedeps = "freetype",
                shflags = ldflags, 
                ldflags = ldflags
            }

            local freetypefetch = freetype:fetch()
            if freetypefetch and freetypefetch.static then
                -- translate paths
                function _translate_paths(paths)
                    if is_host("windows") then
                        if type(paths) == "string" then
                            return (paths:gsub("\\", "/"))
                        elseif type(paths) == "table" then
                            local result = {}
                            for _, p in ipairs(paths) do
                                table.insert(result, (p:gsub("\\", "/")))
                            end
                            return result
                        end
                    end
                    return paths
                end

                import("core.tool.linker")
                function _map_linkflags(package, targetkind, sourcekinds, name, values)
                    return linker.map_flags(targetkind, sourcekinds, name, values, {target = package})
                end

                local add_dep
                add_dep = function (dep)
                    print("add_dep", dep:name())
                    local fetchinfo = dep:fetch({external = false})
                    if fetchinfo then
                        print("fetchinfo ", fetchinfo)
                        ldflags = ldflags or {}
                        table.join2(ldflags, _translate_paths(_map_linkflags(package, "binary", {"cxx"}, "linkdir", fetchinfo.linkdirs)))
                        table.join2(ldflags, _map_linkflags(package, "binary", {"cxx"}, "link", fetchinfo.links))
                        table.join2(ldflags, _translate_paths(_map_linkflags(package, "binary", {"cxx"}, "syslink", fetchinfo.syslinks)))
                        table.join2(ldflags, _map_linkflags(package, "binary", {"cxx"}, "framework", fetchinfo.frameworks))
                        if fetchinfo.static then
                            for _, inner_dep in ipairs(dep:plaindeps()) do
                                add_dep(inner_dep)
                            end
                        end
                    end
                end

                for _, dep in ipairs(freetype:plaindeps()) do
                    add_dep(dep)
                end
            end
        end
        print("configs", configs)
        print("opt", opt)
        table.insert(configs, "--trace")
        import("package.tools.cmake").install(package, configs, opt)
    end)

    on_test(function (package)
        assert(package:has_cfuncs("TTF_Init", {includes = "SDL2/SDL_ttf.h", configs = {defines = "SDL_MAIN_HANDLED"}}))
    end)
