module subtractor_fsm (
    input wire clk,       // 时钟信号
    input wire reset,     // 复位信号
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output wire [7:0] res // 差
);

// 状态控制模块
subtractor_state_ctrl state_ctrl (
    .clk(clk),
    .reset(reset),
    .state(state)
);

// 计算模块
subtractor_calc calc (
    .clk(clk),
    .reset(reset),
    .state(state),
    .a(a),
    .b(b),
    .res(res)
);

endmodule

// 状态控制子模块
module subtractor_state_ctrl (
    input wire clk,
    input wire reset,
    output reg [1:0] state
);

localparam IDLE = 2'b00;
localparam CALC = 2'b01;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
    end else begin
        case (state)
            IDLE: state <= CALC;
            CALC: state <= IDLE;
            default: state <= IDLE;
        endcase
    end
end

endmodule

// 计算子模块
module subtractor_calc (
    input wire clk,
    input wire reset,
    input wire [1:0] state,
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] res
);

localparam IDLE = 2'b00;
localparam CALC = 2'b01;

wire [7:0] diff;
assign diff = a - b;  // 提前计算差值

always @(posedge clk or posedge reset) begin
    if (reset) begin
        res <= 0;
    end else begin
        case (state)
            CALC: res <= diff;
            default: res <= res;  // 保持当前值
        endcase
    end
end

endmodule