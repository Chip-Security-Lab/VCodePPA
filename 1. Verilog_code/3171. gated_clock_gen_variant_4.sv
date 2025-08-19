//SystemVerilog
module gated_clock_gen(
    input master_clk,
    input gate_enable,
    input rst,
    output gated_clk
);
    reg latch_enable;
    
    always @(negedge master_clk or posedge rst)
        latch_enable <= rst ? 1'b0 : gate_enable;
    
    assign gated_clk = master_clk & latch_enable;
endmodule