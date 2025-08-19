module d_latch_scannable (
    input wire d,
    input wire scan_in,
    input wire scan_en,
    input wire enable,
    output reg q
);
    wire mux_out;
    
    assign mux_out = scan_en ? scan_in : d;
    
    always @* begin
        if (enable)
            q = mux_out;
    end
endmodule