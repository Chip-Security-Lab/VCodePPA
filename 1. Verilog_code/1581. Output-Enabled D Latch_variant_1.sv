//SystemVerilog
module d_latch_out_enable (
    input wire d,
    input wire latch_en,
    input wire out_en,
    output wire q
);
    reg q_internal;
    
    always @* begin
        if (latch_en)
            q_internal = d;
    end
    
    wire [1:0] mux_sel = {out_en, q_internal};
    wire [3:0] mux_out;
    
    assign mux_out = (mux_sel == 2'b00) ? 4'bzzzz :
                    (mux_sel == 2'b01) ? 4'bzzzz :
                    (mux_sel == 2'b10) ? 4'b0000 :
                    4'b1111;
    
    assign q = mux_out[0];
endmodule