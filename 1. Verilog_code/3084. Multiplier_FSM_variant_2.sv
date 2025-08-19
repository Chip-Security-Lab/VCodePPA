//SystemVerilog
// Brent-Kung加法器黑金块
module brent_kung_adder #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    wire [WIDTH:0] carry;
    assign carry[0] = 1'b0;
    
    // 生成(G)和传播(P)信号
    wire [WIDTH-1:0] g, p;
    
    // 第一级: 生成初始的G和P
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] | b[i];
        end
    endgenerate
    
    // 第二级: 计算群组G和P (第一阶段)
    wire [WIDTH/2-1:0] g_group1, p_group1;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : gen_group1
            assign g_group1[i] = g[2*i+1] | (p[2*i+1] & g[2*i]);
            assign p_group1[i] = p[2*i+1] & p[2*i];
        end
    endgenerate
    
    // 第三级: 计算群组G和P (第二阶段)
    wire [WIDTH/4-1:0] g_group2, p_group2;
    generate
        for (i = 0; i < WIDTH/4; i = i + 1) begin : gen_group2
            assign g_group2[i] = g_group1[2*i+1] | (p_group1[2*i+1] & g_group1[2*i]);
            assign p_group2[i] = p_group1[2*i+1] & p_group1[2*i];
        end
    endgenerate
    
    // 计算进位
    assign carry[1] = g[0];
    
    // 2位
    assign carry[2] = g_group1[0];
    
    // 3位
    assign carry[3] = g[2] | (p[2] & carry[2]);
    
    // 4位
    assign carry[4] = g_group2[0];
    
    // 计算最终和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
        end
    endgenerate
endmodule

module Multiplier_FSM #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input start,
    input [WIDTH-1:0] multiplicand, 
    input [WIDTH-1:0] multiplier,
    output reg [2*WIDTH-1:0] product,
    output reg done
);
    // 使用localparam替代typedef enum
    localparam IDLE = 3'b000, INIT = 3'b001, ADD = 3'b010, SHIFT = 3'b011, DONE = 3'b100;
    reg [2:0] current_state, next_state;
    
    reg [WIDTH-1:0] mplier;
    reg [2*WIDTH-1:0] accum;
    reg [3:0] counter;
    reg [WIDTH-1:0] mcand_reg; // 添加寄存器存储被乘数
    
    // 定义加法器输入输出
    wire [2*WIDTH-1:0] add_a;
    wire [2*WIDTH-1:0] add_b;
    wire [2*WIDTH-1:0] add_sum;
    
    // 加法输入准备
    assign add_a = accum;
    assign add_b = mplier[0] ? {mcand_reg, {WIDTH{1'b0}}} : {2*WIDTH{1'b0}};
    
    // 实例化Brent-Kung加法器
    brent_kung_adder #(
        .WIDTH(2*WIDTH)
    ) adder_inst (
        .a(add_a),
        .b(add_b),
        .sum(add_sum)
    );

    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= IDLE;
        else current_state <= next_state;
    end

    // 次态逻辑
    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: next_state = start ? INIT : IDLE;
            INIT: next_state = ADD;
            ADD: next_state = SHIFT;
            SHIFT: next_state = (counter == WIDTH-1) ? DONE : ADD;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 数据路径控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum <= 0;
            mplier <= 0;
            mcand_reg <= 0;
            counter <= 0;
            product <= 0;
            done <= 0;
        end else begin
            done <= 0;
            case(current_state)
                INIT: begin
                    accum <= 0;
                    mplier <= multiplier;
                    mcand_reg <= multiplicand;
                    counter <= 0;
                end
                ADD: accum <= add_sum;
                SHIFT: begin
                    accum <= {1'b0, accum[2*WIDTH-1:1]};
                    mplier <= {1'b0, mplier[WIDTH-1:1]};
                    counter <= counter + 1;
                end
                DONE: begin
                    product <= accum;
                    done <= 1;
                end
                default: ; // 默认不操作
            endcase
        end
    end
endmodule