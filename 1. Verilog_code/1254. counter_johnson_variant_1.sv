//SystemVerilog
module counter_johnson #(parameter STAGES=4) (
    input clk, rst,
    output reg [STAGES-1:0] j_reg
);
    always @(posedge clk) begin
        if (rst) begin
            j_reg <= 0;
        end
        else begin
            j_reg <= {j_reg[STAGES-2:0], ~j_reg[STAGES-1]};
        end
    end
endmodule