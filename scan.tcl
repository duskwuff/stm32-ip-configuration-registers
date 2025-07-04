proc ipconfig_scan {workaddr startaddr endaddr} {
    if {[expr {$startaddr & 0x3ff}] != 0} {
        echo "startaddr must be aligned to a 1K page"
        return
    }

    mww $workaddr [expr { $workaddr + 0x21 }] 8

    write_memory [expr {$workaddr + 0x20}] 16 {
        0x9b06 0x3308 0x9306 0x4770 0x2280 0x00d2 0x6803 0x2b00
        0xd000 0xbe00 0x1880 0x4288 0xd3f8 0xbe00
    }

    # VTOR
    mww 0xe000ed08 $workaddr

    reg r0 [expr {$startaddr + 0x3fc}]
    reg r1 $endaddr
    reg pc [expr {$workaddr + 0x28}]
    reg sp [expr {$workaddr + 0x100}]

    set results {"BASE_ADDR,SIDR_ADDR,HWCFG3,HWCFG2,HWCFG1,VER,IPID,SIDR,NAME,NOTES"}

    while 1 {
        resume
        wait_halt
        set sidr_addr [dict values [get_reg r0]]
        if { $sidr_addr >= $endaddr } { break }

        set ipconfig [read_memory [expr {$sidr_addr - 20}] 32 6]
        set sidr [lindex $ipconfig 5]

        if {[expr {$sidr & ~0xff}] != 0xa3c5dd00} { continue }

        set base 0
        if { $sidr == 0xa3c5dd01 } { set base [expr {$sidr_addr - 1024 + 4}] }
        if { $sidr == 0xa3c5dd02 } { set base [expr {$sidr_addr - 2048 + 4}] }
        if { $sidr == 0xa3c5dd04 } { set base [expr {$sidr_addr - 4096 + 4}] }
        if { $sidr == 0xa3c5dd08 } { set base [expr {$sidr_addr - 8192 + 4}] }

        lappend results [format "%08x,%08x,%s,-," $base $sidr_addr [join [lmap x $ipconfig {format "%08x" $x}] ","]]
    }

    echo "\n"
    echo [join $results "\n"]
}

proc ipconfig_probe {addr} {
    set sidr_addr [expr {($addr & ~0x3ff) + 0x3fc}]

    set ipconfig [read_memory [expr {$sidr_addr - 20}] 32 6]
    set sidr [lindex $ipconfig 5]

    set base $addr
    if { $sidr == 0xa3c5dd01 } { set base [expr {$sidr_addr - 1024 + 4}] }
    if { $sidr == 0xa3c5dd02 } { set base [expr {$sidr_addr - 2048 + 4}] }
    if { $sidr == 0xa3c5dd04 } { set base [expr {$sidr_addr - 4096 + 4}] }
    if { $sidr == 0xa3c5dd08 } { set base [expr {$sidr_addr - 8192 + 4}] }

    echo [format "%08x,%08x,%s,-," $base $sidr_addr [join [lmap x $ipconfig {format "%08x" $x}] ","]]
}
