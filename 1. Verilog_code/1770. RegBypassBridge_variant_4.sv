//SystemVerilog
module RegBypassBridge #(
    parameter WIDTH = 32
)(
    input clk, rst_n,
    input [WIDTH-1:0] reg_in,
    output reg [WIDTH-1:0] reg_out,
    input bypass_en
);
    // 优化寄存器更新逻辑，消除冗余赋值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_out <= {WIDTH{1'b0}}; // 添加复位逻辑以确保确定性初始状态
        end else if (bypass_en) begin
            reg_out <= reg_in; // 仅在bypass_en有效时更新寄存器
        end
        // 移除了else分支中的冗余自赋值操作
    end
endmodule