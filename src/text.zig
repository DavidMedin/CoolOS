pub const ssfn = @cImport({
    @cDefine("SSFN_MAXLINES", "4096");
    //SSFN_CONSOLEBITMAP_PALETTE
    @cDefine("SSFN_CONSOLEBITMAP_TRUECOLOR", {});
    @cDefine("NULL", "0"); // Never thought I'd have to do this for C.
    @cInclude("scalable-font2/ssfn.h");
});

// Allows 'text.ssfn_putc' in other files, instead of `text.ssfn.ssfn_putc'.
pub usingnamespace ssfn;

export var ssfn_src : *ssfn.ssfn_font_t = @ptrCast( @constCast( @embedFile("resources/fonts/lanapixel.sfn" ) ) );
// SFN Docs are wrong, ssfn_dist is a ssfn_buf_t, not a *ssfn_buf_t!
export var ssfn_dst : ssfn.ssfn_buf_t = undefined;
