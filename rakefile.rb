require File.expand_path("rakehelp/freebasic", File.dirname(__FILE__))
require "rake/packagetask"

PRODUCT_NAME = "service_wrapper"
PRODUCT_VERSION = "0.1.2"
PRODUCT_RELEASE = "#{PRODUCT_NAME}-#{PRODUCT_VERSION}-win32.zip"

defaults = {
  :mt       => true,                       # we require multithread
  :pedantic => true,                       # noisy warnings
  :trace    => ENV.fetch("TRACE", false),  # generate a log file
  :debug    => ENV.fetch("DEBUG", false)   # optional debugging
}

task :default => [:build]

task :build   => ["lib:mini_service", "test:build", "service_wrapper:build"]
task :run     => ["test:run"]
task :rebuild => ["test:rebuild"]
task :package => ["build"]
task :clobber => ["test:clobber"]

project_task "service_wrapper" do
  executable  "service_wrapper"
  build_to    "bin"

  if defaults[:trace]
    define "_TRACE_FILE"
  end

  search_path "inc"
  search_path "vendor/mini_service/inc"

  lib_path    "vendor/mini_service/lib/win32"

  main        "src/main.bas"
  source      "src/*.bas"

  library     "mini_service"

  option defaults
end

namespace "test" do
  project_task "mock_process" do
    executable "mock_process"
    build_to   "test"

    main       "test/fixtures/mock_process.bas"
  end

  project_task "test_runner" do
    executable  "runner"
    build_to    "test"

    search_path "inc"
    search_path "vendor/mini_service/inc"

    lib_path    "vendor/mini_service/lib/win32"

    main        "test/helper.bas"
    source      "test/test_*.bas"

    source      "src/configuration_file.bas"
    source      "src/console_process.bas"

    library     "mini_service"

    option defaults
  end

  task :run => ["test_runner:build", "mock_process:build"] do
    chdir "test" do
      sh "runner.exe"
    end
  end
end

namespace "lib" do
  mini_service_dir  = "vendor/mini_service"
  mini_service_rake = File.join(mini_service_dir, "Rakefile")
  mini_service_lib  = File.join(mini_service_dir, "lib", "win32", "libmini_service.a")

  desc "Build mini_service library (dependency)"
  task "mini_service" => [mini_service_lib]

  file mini_service_lib => [mini_service_rake] do
    chdir mini_service_dir do
      ruby "-S rake lib:build"
    end
  end
end

# FIXME: Source code package
Rake::PackageTask.new(PRODUCT_NAME, PRODUCT_VERSION) do |pkg|
  pkg.need_zip = true
  pkg.package_files = FileList[
    "examples/**/*.{conf,rb,ru,md}", "inc/*.bi", "src/*.bas",
    "README.md", "LICENSE.txt", "History.txt",
    "rakehelp/freebasic.rb", "rakefile.rb"
  ]
end

# FIXME: Fix binary package
desc "Build binary packages"
task :release => ["pkg/#{PRODUCT_RELEASE}"]
task :package => [:release]

file "pkg/#{PRODUCT_RELEASE}" => ["pkg"] do |f|
  zipfile = File.basename(f.name)
  dirname = zipfile.gsub(File.extname(zipfile), "")

  base    = File.join("pkg", dirname)
  bin_dir = File.join(base, "bin")
  doc_dir = File.join(base, "docs", PRODUCT_NAME)
  exa_dir = File.join(base, "examples", PRODUCT_NAME)

  mkdir_p bin_dir
  mkdir_p doc_dir
  mkdir_p exa_dir

  cp FileList["bin/*.exe"], bin_dir

  Dir.glob("examples/**/*.{conf,rb,ru,md}").each do |f|
    dir = File.join(exa_dir, File.dirname(f))
    mkdir_p dir unless File.directory?(dir)
    cp f, dir
  end

  cp "README.md", doc_dir
  cp "History.txt", doc_dir
  cp "LICENSE.txt", doc_dir

  chdir "pkg" do
    sh "zip -r #{zipfile} #{dirname}"
  end
end
