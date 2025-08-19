//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module Hybrid_AND(
    input [1:0] ctrl,
    input [7:0] base,
    output reg [7:0] result
);
    // 简化布尔逻辑表达式实现
    always @(*) begin
        // 只有在ctrl=2'b00时应用8'h0F掩码，在ctrl=2'b01时应用8'hF0掩码
        // ctrl[1]为1时，结果始终为0
        if (ctrl[1]) begin
            result = 8'h00;
        end else if (ctrl[0]) begin
            result = base & 8'hF0; // 保留高4位
        end else begin
            result = base & 8'h0F; // 保留低4位
        end
    end
endmodule