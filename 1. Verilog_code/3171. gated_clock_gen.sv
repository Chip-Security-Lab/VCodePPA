module gated_clock_gen(
    input master_clk,
    input gate_enable,
    input rst,
    output gated_clk
);
    reg latch_enable;
    
    always @(negedge master_clk or posedge rst) begin
        if (rst)
            latch_enable <= 1'b0;
        else
            latch_enable <= gate_enable;
    end
    
    assign gated_clk = master_clk & latch_enable;
endmodule