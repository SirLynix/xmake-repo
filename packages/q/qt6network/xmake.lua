package("qt6network")
    set_base("qt6lib")
    set_kind("library")

    on_load(function (package)
        package:add("deps", "qt6core", {debug = package:is_debug(), version = package:version_str()})
        package:data_set("libname", "Network")

        if package:is_plat("linux") then
            -- we need system openssl with evp-kdf
            -- @see https://github.com/xmake-io/xmake-repo/pull/1057#issuecomment-1069006866
            if linuxos.name() == "fedora" then
                package:add("deps", "openssl", {system = true})
            else
                package:add("deps", "openssl")
            end
        elseif package:is_plat("iphoneos") then
            package:data_set("frameworks", {"GSS", "IOKit", "Security", "SystemConfiguration"})
        end

        package:base():script("load")(package)
        package:set("kind", "library")
    end)

    on_test(function (package)
        local cxflags
        if package:is_plat("windows") then
            cxflags = "/Zc:__cplusplus"
        else
            cxflags = "-fPIC"
        end
        assert(package:check_cxxsnippets({test = [[
            int test(int argc, char** argv) {
                QCoreApplication app(argc, argv);

                QByteArray datagram = "Hello from xmake!";
                QUdpSocket udpSocket;
                udpSocket.writeDatagram(datagram, QHostAddress::Broadcast, 45454);

                return app.exec();
            }
        ]]}, {configs = {languages = "c++17", cxflags = cxflags}, includes = {"QCoreApplication", "QByteArray", "QUdpSocket"}}))
    end)
