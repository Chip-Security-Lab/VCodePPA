//SystemVerilog
// IEEE 1364-2005 Verilog标准
module locking_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire lock_req,
    input wire unlock_req,
    input wire capture,
    output reg [WIDTH-1:0] shadow_data,
    output reg locked
);
    // 锁定状态控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            locked <= 1'b0;
        end
        else if (lock_req) begin
            locked <= 1'b1;
        end
        else if (unlock_req) begin
            locked <= 1'b0;
        end
    end
    
    // 数据捕获逻辑 - 只在未锁定且捕获信号有效时更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= {WIDTH{1'b0}};
        end
        else if (capture && !locked) begin
            shadow_data <= data_in;
        end
    end
endmodule