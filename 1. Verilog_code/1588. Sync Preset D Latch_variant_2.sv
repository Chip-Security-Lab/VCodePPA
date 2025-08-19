//SystemVerilog
module d_latch_sync_preset (
    input wire d,
    input wire enable, 
    input wire preset,
    output wire q
);

    wire d_muxed = enable ? d : 1'b0;
    wire preset_muxed = enable ? preset : 1'b0;
    wire q_int = enable ? (preset_muxed ? 1'b1 : d_muxed) : q;
    
    reg q_reg;
    always @* begin
        q_reg = q_int;
    end
    
    assign q = q_reg;

endmodule