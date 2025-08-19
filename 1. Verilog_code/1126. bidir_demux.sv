module bidir_demux (
    inout wire common_io,                // Bidirectional common port
    inout wire [3:0] channel_io,         // Bidirectional channel ports
    input wire [1:0] channel_sel,        // Channel selection
    input wire direction                 // 0: in→out, 1: out→in
);
    // Direction control with demux/mux functionality
    assign common_io = direction ? channel_io[channel_sel] : 1'bz;
    assign channel_io[0] = (!direction && channel_sel == 2'b00) ? common_io : 1'bz;
    assign channel_io[1] = (!direction && channel_sel == 2'b01) ? common_io : 1'bz;
    assign channel_io[2] = (!direction && channel_sel == 2'b10) ? common_io : 1'bz;
    assign channel_io[3] = (!direction && channel_sel == 2'b11) ? common_io : 1'bz;
endmodule