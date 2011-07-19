#include once "helper.bi"
#include once "console_process.bi"

namespace TestConsoleProcess
    sub test_require_executable()
        var child = new ConsoleProcess("prog.exe")
        assert(child->executable = "prog.exe")
        delete child
    end sub

    sub test_optional_arguments()
        var child = new ConsoleProcess("prog.exe", "arg1 arg2")
        assert(child->arguments = "arg1 arg2")
        delete child
    end sub

    sub test_start_failed()
        var child = new ConsoleProcess("invalid.exe")
        assert(child->start() = 0)
        delete child
    end sub

    sub test_start_succeed()
        var child = new ConsoleProcess("fixtures/mock_process.exe")
        assert(child->start())
        delete child
    end sub

    sub run()
        test_require_executable
        test_optional_arguments
        test_start_failed
        test_start_succeed
    end sub
end namespace

TestConsoleProcess.run()
