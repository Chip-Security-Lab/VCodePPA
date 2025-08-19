//SystemVerilog
// 组合逻辑模块
module seq_detector_comb(
    input wire [3:0] state,
    input wire x,
    output reg [3:0] next_state
);

    // 状态定义
    localparam S0 = 4'b0001;
    localparam S1 = 4'b0010;
    localparam S2 = 4'b0100;
    localparam S3 = 4'b1000;

    // 组合逻辑状态转换
    always @(*) begin
        next_state = S0; // 默认状态
        case (1'b1)
            state[0]: next_state = x ? S1 : S0;
            state[1]: next_state = x ? S1 : S2;
            state[2]: next_state = x ? S3 : S0;
            state[3]: next_state = x ? S1 : S2;
            default: next_state = S0;
        endcase
    end

endmodule

// 时序逻辑模块
module seq_detector_seq(
    input wire clk,
    input wire rst_n,
    input wire x,
    input wire [3:0] next_state,
    output reg [3:0] state,
    output reg x_reg
);

    // 状态定义
    localparam S0 = 4'b0001;
    localparam S1 = 4'b0010;
    localparam S2 = 4'b0100;
    localparam S3 = 4'b1000;

    // 状态和输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S0;
            x_reg <= 1'b0;
        end else begin
            state <= next_state;
            x_reg <= x;
        end
    end

endmodule

// 顶层模块
module seq_detector_0110(
    input wire clk,
    input wire rst_n,
    input wire x,
    output reg z
);

    // 状态定义
    localparam S0 = 4'b0001;
    localparam S1 = 4'b0010;
    localparam S2 = 4'b0100;
    localparam S3 = 4'b1000;

    wire [3:0] next_state;
    wire [3:0] state;
    wire x_reg;

    // 实例化组合逻辑模块
    seq_detector_comb comb_logic(
        .state(state),
        .x(x),
        .next_state(next_state)
    );

    // 实例化时序逻辑模块
    seq_detector_seq seq_logic(
        .clk(clk),
        .rst_n(rst_n),
        .x(x),
        .next_state(next_state),
        .state(state),
        .x_reg(x_reg)
    );

    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            z <= 1'b0;
        else
            z <= (state == S3) && (x_reg == 1'b0);
    end

endmodule