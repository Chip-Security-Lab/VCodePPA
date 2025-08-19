//SystemVerilog
module d_latch_registered (
    input wire d,
    input wire latch_enable,
    input wire clk,
    output reg q_reg
);

    reg latch_out_reg;
    
    always @(posedge clk) begin
        if (latch_enable)
            latch_out_reg <= d;
    end
    
    always @(posedge clk) begin
        q_reg <= latch_out_reg;
    end

endmodule