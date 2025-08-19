module subtractor_fsm (
    input wire clk,       // 时钟信号
    input wire reset,     // 复位信号
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output reg [7:0] res  // 差
);

reg [1:0] state;          // 状态寄存器

// 状态定义
localparam IDLE = 2'b00;
localparam CALC = 2'b01;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        res <= 0;
    end else begin
        case (state)
            IDLE: begin
                state <= CALC;
            end
            CALC: begin
                res <= a - b;
                state <= IDLE;
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule