function sh_quote(s) {
    gsub(/'/, "'\\''", s)
    return "'" s "'"
}

function run(prog, arg1, arg2, arg3,    cmd, out, line) {
    cmd = prog
    if (arg1 != "") cmd = cmd " " sh_quote(arg1)
    if (arg2 != "") cmd = cmd " " sh_quote(arg2)
    if (arg3 != "") cmd = cmd " " sh_quote(arg3)

    out = ""
    while ((cmd | getline line) > 0) {
        out = (out == "" ? line : out "\n" line)
    }
    close(cmd)
    return out
}

BEGIN {
    var1 = run("my_cmd", "hello world")
    var2 = run("my_cmd", "it's got 'quotes' & $symbols")
    var3 = run("my_cmd", "first arg", "second arg")

    print "Result 1:", var1
    print "Result 2:", var2
    print "Result 3:", var3
}
