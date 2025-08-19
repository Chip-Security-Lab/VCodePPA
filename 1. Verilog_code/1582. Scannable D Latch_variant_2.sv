//SystemVerilog
module scan_mux (
    input wire d,
    input wire scan_in,
    input wire scan_en,
    output wire mux_out
);
    assign mux_out = scan_en ? scan_in : d;
endmodule

module d_latch (
    input wire d,
    input wire enable,
    output reg q
);
    always @* begin
        if (enable)
            q = d;
    end
endmodule

module d_latch_scannable (
    input wire d,
    input wire scan_in,
    input wire scan_en,
    input wire enable,
    output wire q
);
    wire mux_out;
    
    scan_mux mux_inst (
        .d(d),
        .scan_in(scan_in),
        .scan_en(scan_en),
        .mux_out(mux_out)
    );
    
    d_latch latch_inst (
        .d(mux_out),
        .enable(enable),
        .q(q)
    );
endmodule