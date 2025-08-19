//SystemVerilog
module fsm_controlled_shifter (
    input clk, rst, start,
    input [31:0] data,
    input [4:0] total_shift,
    output reg done,
    output reg [31:0] result
);
// 用参数定义状态常量
localparam IDLE = 1'b0;
localparam SHIFT = 1'b1;

reg state; // 状态寄存器
reg [4:0] cnt;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        cnt <= 5'b0;
        result <= 32'b0;
        done <= 1'b0;
    end else begin
        // 扁平化后的条件结构
        if (state == IDLE && start) begin
            result <= data;
            cnt <= total_shift;
            state <= SHIFT;
            done <= 1'b0;
        end else if (state == SHIFT && |cnt) begin
            result <= result << 1;
            cnt <= cnt - 5'd1;
        end else if (state == SHIFT && ~|cnt) begin
            done <= 1'b1;
            state <= IDLE;
        end else if (state != IDLE && state != SHIFT) begin
            state <= IDLE;
        end
    end
end
endmodule