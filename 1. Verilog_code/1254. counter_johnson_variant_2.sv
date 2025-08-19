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
        // 合并流水线级，直接从j_reg[0]取反并反馈
        j_reg <= {j_reg[STAGES-2:0], ~j_reg[STAGES-1]};
    end
end
endmodule