String createRcFile(String runtimeDir, String sharedPath){
  return '''
alias ll="ls -l"
alias la="ls -a"


export LD_LIBRARY_PATH=$runtimeDir/node/lib:$sharedPath:\$LD_LIBRARY_PATH
export NODE_OPTIONS="--require $runtimeDir/node/error_handler.js"

export PATH=/data/data/com.vsdroid/bin:/data/data/com.vsdroid/runtimes/node/node_modules/bin:\$PATH

run_java_tool() {
  local tool="\$1"
  shift
  if [ ! -d $runtimeDir/java-17-openjdk ]; then
    echo "${notFoundmessage('OpenJDK')}"
  else
    LD_LIBRARY_PATH=$runtimeDir/java-17-openjdk/lib:\$LD_LIBRARY_PATH \\
    JAVA_HOME=$runtimeDir/java-17-openjdk \\
    $sharedPath/lib\${tool}.so "\$@"
  fi
}

jar()         { run_java_tool jar "\$@"; }
jarsigner()   { run_java_tool jarsigner "\$@"; }
java()        { run_java_tool java "\$@"; }
javac()       { run_java_tool javac "\$@"; }
javadoc()     { run_java_tool javadoc "\$@"; }
javap()       { run_java_tool javap "\$@"; }
jcmd()        { run_java_tool jcmd "\$@"; }
jconsole()    { run_java_tool jconsole "\$@"; }
jdb()         { run_java_tool jdb "\$@"; }
jdeprscan()   { run_java_tool jdeprscan "\$@"; }
jdeps()       { run_java_tool jdeps "\$@"; }
jfr()         { run_java_tool jfr "\$@"; }
jhsdb()       { run_java_tool jhsdb "\$@"; }
jimage()      { run_java_tool jimage "\$@"; }
jinfo()       { run_java_tool jinfo "\$@"; }
jlink()       { run_java_tool jlink "\$@"; }
jmap()        { run_java_tool jmap "\$@"; }
jmod()        { run_java_tool jmod "\$@"; }
jpackage()    { run_java_tool jpackage "\$@"; }
jps()         { run_java_tool jps "\$@"; }
jrunscript()  { run_java_tool jrunscript "\$@"; }
jstack()      { run_java_tool jstack "\$@"; }
jstat()       { run_java_tool jstat "\$@"; }
jstatd()      { run_java_tool jstatd "\$@"; }
keytool()     { run_java_tool keytool "\$@"; }
rmiregistry() { run_java_tool rmiregistry "\$@"; }
serialver()   { run_java_tool serialver "\$@"; }

kotlinc() {
  if [ ! -d $runtimeDir/kotlin ]; then
    echo "${notFoundmessage('Kotlin')}"
  else
    if [ ! -d $runtimeDir/kotlin/tmp ]; then
      mkdir $runtimeDir/kotlin/tmp
    fi
    LD_LIBRARY_PATH=$runtimeDir/java-17-openjdk/lib:\$LD_LIBRARY_PATH \\
    JAVA_HOME=$runtimeDir/java-17-openjdk \\
    JAVA_OPTS="\$JAVA_OPTS -Djansi.passthrough=true -Djansi.force=false" \\
    TMPDIR=$runtimeDir/kotlin/tmp \\
    echo "Compiling..."
    java \\
      -Djansi.passthrough=true \\
      -Djansi.strip=true \\
      -Dorg.fusesource.jansi.AnsiConsole=false \\
      -Djava.io.tmpdir=$runtimeDir/kotlin/tmp \\
      -cp "$runtimeDir/kotlin/lib/*" \\
      org.jetbrains.kotlin.cli.jvm.K2JVMCompiler \\
    "\$@"
  fi
}

alias kotlin="java"

clang() {
  if [ ! -d $runtimeDir/clang ]; then
    echo "${notFoundmessage('Clang')}"
  else
    ln -sf $sharedPath/liblld.so $runtimeDir/clang/ld.lld

    export PATH=$runtimeDir/clang:\$PATH

    LD_LIBRARY_PATH=$runtimeDir/clang:\$LD_LIBRARY_PATH \\
    C_INCLUDE_PATH=$runtimeDir/clang/sysroot/usr/include:$runtimeDir/clang/lib/clang/20/include \\
    CPLUS_INCLUDE_PATH=$runtimeDir/clang/sysroot/usr/include:$runtimeDir/clang/lib/clang/20/include \\
    $sharedPath/libclang-20.so \\
      -fuse-ld=lld \\
      -L$runtimeDir/clang/lib/clang/20/lib/linux \\
      -B$runtimeDir/clang/lib/clang/20/lib/linux \\
      -resource-dir=$runtimeDir/clang/lib/clang/20 \\
      "\$@"
  fi
}

clang++() {
  if [ ! -d $runtimeDir/clang ]; then
    echo "${notFoundmessage('Clang')}"
    return 1
  fi

  local is_help_request=0
  for arg in "\$@"; do
    case "\$arg" in
      --version|-v|--help|-h)
        is_help_request=1
        break
        ;;
    esac
  done

  if [ \$is_help_request -eq 0 ]; then
    local has_input_files=0
    for arg in "\$@"; do
      if [[ "\$arg" != -* ]] && [[ "\$arg" != - ]]; then
        has_input_files=1
        break
      fi
    done

    if [ \$has_input_files -eq 0 ]; then
      echo "error: no input files" >&2
      echo "Usage: clang++ [options] file..." >&2
      return 1
    fi
  fi

  ln -sf $sharedPath/liblld.so $runtimeDir/clang/ld.lld
  export PATH=$runtimeDir/clang:\$PATH

  LD_LIBRARY_PATH=$runtimeDir/clang:$runtimeDir/clang/lib/clang/20/lib/linux:\$LD_LIBRARY_PATH \\
  CPLUS_INCLUDE_PATH=$runtimeDir/clang/sysroot/usr/include/c++/v1:$runtimeDir/clang/sysroot/usr/include:$runtimeDir/clang/lib/clang/20/include \\
  C_INCLUDE_PATH=$runtimeDir/clang/sysroot/usr/include:$runtimeDir/clang/lib/clang/20/include \\
  $sharedPath/libclang-20.so \\
    -fuse-ld=lld \\
    -x c++ \\
    -std=c++20 \\
    -stdlib=libc++ \\
    -lc++ \\
    -L$runtimeDir/clang/lib/clang/20/lib/linux \\
    -B$runtimeDir/clang/lib/clang/20/lib/linux \\
    -resource-dir=$runtimeDir/clang/lib/clang/20 \\
    "\$@"
}

clangloader() {
  if [ ! -d $runtimeDir/clang ]; then
    echo "${notFoundmessage('Clang')}"
  else
    LD_LIBRARY_PATH=$runtimeDir/clang/lib/clang/20/lib/linux:$runtimeDir/clang:\$LD_LIBRARY_PATH \\
    $sharedPath/libclangloader.so "\$@"
  fi
}

python() {
  if [ ! -d $runtimeDir/python ]; then
    echo "${notFoundmessage('Python')}"
  else
    LD_LIBRARY_PATH=$runtimeDir/python/lib:\$LD_LIBRARY_PATH \\
    PYTHONHOME=$runtimeDir/python \\
    PATH=$runtimeDir/python/bin:\$PATH \\
    $sharedPath/libpythonlauncher.so "\$@"
  fi
}

python3() {
  if [ ! -d $runtimeDir/python ]; then
    echo "${notFoundmessage('Python')}"
  else
    LD_LIBRARY_PATH=$runtimeDir/python/lib:\$LD_LIBRARY_PATH \\
    PYTHONHOME=$runtimeDir/python \\
    PATH=$runtimeDir/python/bin:\$PATH \\
    $sharedPath/libpythonlauncher.so "\$@"
  fi
}

if [ ! -f $runtimeDir/python/bin/pip3 ]; then
  echo "Installing pip..."
  LD_LIBRARY_PATH=$runtimeDir/python/lib:\$LD_LIBRARY_PATH \\
  PYTHONHOME=$runtimeDir/python \\
  PATH=$runtimeDir/python/bin \\
  $sharedPath/libpythonlauncher.so -m ensurepip
fi

pip() {
  LD_LIBRARY_PATH=$runtimeDir/python/lib:\$LD_LIBRARY_PATH PYTHONHOME=$runtimeDir/python PATH=$runtimeDir/python/bin python -m pip "\$@"
}

pip3() {
  LD_LIBRARY_PATH=$runtimeDir/python/lib:\$LD_LIBRARY_PATH PYTHONHOME=$runtimeDir/python PATH=$runtimeDir/python/bin python -m pip "\$@"
}

npm() {
  echo "prefix=/data/data/com.vsdroid/runtimes/node" > ~/.npmrc
  NODE_OPTIONS="--dns-result-order=ipv4first" \\
  node $runtimeDir/node/lib/node_modules/npm/bin/npm-cli.js \\
  "\$@"
}

npx() {
  echo "prefix=/data/data/com.vsdroid/runtimes/node" > ~/.npmrc
  NODE_OPTIONS="--dns-result-order=ipv4first" \\
  node $runtimeDir/node/lib/node_modules/npm/bin/npx-cli.js \\
  "\$@"
}
''';
}

String notFoundmessage (String binName) => "$binName is not installed. Go to the download page and install it first.";