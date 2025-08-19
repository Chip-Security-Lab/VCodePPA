//SystemVerilog
module pl_reg_bitslice #(parameter W=8) (
    input clk, en,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);
    // Directly register the output with enable logic
    // This eliminates the intermediate register and moves the register stage
    // forward through the assignment logic
    always @(posedge clk) begin
        if (en)
            data_out <= data_in;
    end
endmodule