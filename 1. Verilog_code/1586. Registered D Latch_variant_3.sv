//SystemVerilog
module d_latch_registered (
    input wire d,
    input wire latch_enable,
    input wire clk,
    output reg q_reg
);
    
    always @(posedge clk) begin
        q_reg <= latch_enable ? d : q_reg;
    end
endmodule