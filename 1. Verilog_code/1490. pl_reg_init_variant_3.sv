//SystemVerilog
module pl_reg_init #(parameter W=8, INIT=0) (
    input clk, init,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);
    // Move registers from input side to output side
    // Apply forward register retiming

    // Combined logic with register at output
    always @(posedge clk)
        data_out <= init ? INIT : data_in;
        
endmodule