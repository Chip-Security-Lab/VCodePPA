//SystemVerilog
module RegBypassBridge #(
    parameter WIDTH = 32
)(
    input clk, rst_n,
    input [WIDTH-1:0] reg_in,
    output reg [WIDTH-1:0] reg_out,
    input bypass_en
);
    // 优化后的代码 - 移除不必要的self-assignment并使用rst_n信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_out <= {WIDTH{1'b0}}; // 复位状态
        end else if (bypass_en) begin
            reg_out <= reg_in;
        end
    end
endmodule