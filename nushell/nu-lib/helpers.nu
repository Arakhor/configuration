# Get short type of pipeline input
#
@category core
export def type []: any -> string {
    describe --detailed | get type
}
