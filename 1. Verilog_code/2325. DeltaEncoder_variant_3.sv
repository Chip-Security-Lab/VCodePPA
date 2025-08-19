//SystemVerilog
module DeltaEncoder (
    input wire clk,
    input wire rst_n,
    input wire [15:0] din,
    output reg [15:0] dout
);

    // 注册前一个输入值
    reg [15:0] prev_value;
    wire [15:0] delta;
    
    // 预计算差值以减少关键路径
    assign delta = din - prev_value;
    
    // 状态更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_value <= 16'h0000;
            dout <= 16'h0000;
        end else begin
            prev_value <= din;
            dout <= delta;
        end
    end

endmodule