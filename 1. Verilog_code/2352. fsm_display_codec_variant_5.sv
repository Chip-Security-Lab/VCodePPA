//SystemVerilog
`timescale 1ns / 1ps

module fsm_display_codec (
    input clk, rst_n,
    input [23:0] pixel_in,
    input start_conversion,
    output [15:0] pixel_out,
    output busy, done
);
    // FSM states
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam OUTPUT = 2'b10;
    
    // 内部信号声明
    wire [1:0] next_state;
    reg [1:0] current_state;
    wire [15:0] processed_data;
    wire [23:0] mult_a, mult_b;
    wire [47:0] mult_result;
    
    // 连接到控制逻辑模块
    fsm_control_logic fsm_control (
        .current_state(current_state),
        .start_conversion(start_conversion),
        .next_state(next_state)
    );
    
    // 连接到数据路径模块
    fsm_datapath fsm_datapath (
        .current_state(current_state),
        .pixel_in(pixel_in),
        .mult_result(mult_result),
        .processed_data(processed_data),
        .mult_a(mult_a),
        .mult_b(mult_b),
        .busy(busy),
        .done(done),
        .pixel_out(pixel_out)
    );
    
    // 实例化Dadda乘法器
    dadda_multiplier_24bit dadda_mult (
        .a(mult_a),
        .b(mult_b),
        .p(mult_result)
    );
    
    // 时序逻辑：状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
endmodule

// 纯组合逻辑：FSM状态转换
module fsm_control_logic (
    input [1:0] current_state,
    input start_conversion,
    output reg [1:0] next_state
);
    // FSM states
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam OUTPUT = 2'b10;
    
    // 纯组合逻辑：下一状态
    always @(*) begin
        case (current_state)
            IDLE: next_state = start_conversion ? PROCESS : IDLE;
            PROCESS: next_state = OUTPUT;
            OUTPUT: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule

// 数据路径模块，包含组合逻辑和时序逻辑
module fsm_datapath (
    input clk, rst_n,
    input [1:0] current_state,
    input [23:0] pixel_in,
    input [47:0] mult_result,
    output reg [15:0] processed_data,
    output reg [15:0] pixel_out,
    output reg [23:0] mult_a, mult_b,
    output reg busy, done
);
    // FSM states
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam OUTPUT = 2'b10;
    
    // 组合逻辑：根据当前状态生成控制信号和数据操作
    wire busy_next, done_next;
    wire [15:0] processed_data_next;
    wire [23:0] mult_a_next, mult_b_next;
    
    // 组合逻辑：计算下一周期的值
    assign busy_next = (current_state == PROCESS) ? 1'b1 : 1'b0;
    assign done_next = (current_state == OUTPUT) ? 1'b1 : 1'b0;
    assign mult_a_next = (current_state == IDLE) ? pixel_in : mult_a;
    assign mult_b_next = (current_state == IDLE) ? 24'h000001 : mult_b;
    assign processed_data_next = (current_state == PROCESS) ? 
                               {mult_result[23:19], mult_result[15:10], mult_result[7:3]} : 
                               processed_data;
    
    // 时序逻辑：更新寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_out <= 16'h0000;
            busy <= 1'b0;
            done <= 1'b0;
            processed_data <= 16'h0000;
            mult_a <= 24'd0;
            mult_b <= 24'd0;
        end else begin
            busy <= busy_next;
            done <= done_next;
            mult_a <= mult_a_next;
            mult_b <= mult_b_next;
            processed_data <= processed_data_next;
            
            // 输出寄存器逻辑
            if (current_state == OUTPUT)
                pixel_out <= processed_data;
        end
    end
endmodule

// 24位Dadda乘法器模块（纯组合逻辑）
module dadda_multiplier_24bit (
    input [23:0] a,
    input [23:0] b,
    output [47:0] p
);
    // 部分积生成
    wire [23:0] pp [23:0];
    
    // 生成部分积矩阵（组合逻辑）
    genvar i, j;
    generate
        for (i = 0; i < 24; i = i + 1) begin: gen_pp_rows
            for (j = 0; j < 24; j = j + 1) begin: gen_pp_cols
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Dadda压缩树信号
    wire [47:0] s_lev1, c_lev1;
    wire [47:0] s_lev2, c_lev2;
    wire [47:0] s_lev3, c_lev3;
    wire [47:0] s_lev4, c_lev4;
    wire [47:0] s_lev5, c_lev5;
    wire [47:0] s_lev6, c_lev6;
    
    // 实例化压缩树各阶段（纯组合逻辑）
    dadda_compressor_stage1 stage1 (
        .pp(pp),
        .s(s_lev1),
        .c(c_lev1)
    );
    
    dadda_compressor_stage2 stage2 (
        .s_in(s_lev1),
        .c_in(c_lev1),
        .s_out(s_lev2),
        .c_out(c_lev2)
    );
    
    dadda_compressor_stage3 stage3 (
        .s_in(s_lev2),
        .c_in(c_lev2),
        .s_out(s_lev3),
        .c_out(c_lev3)
    );
    
    dadda_compressor_stage4 stage4 (
        .s_in(s_lev3),
        .c_in(c_lev3),
        .s_out(s_lev4),
        .c_out(c_lev4)
    );
    
    dadda_compressor_stage5 stage5 (
        .s_in(s_lev4),
        .c_in(c_lev4),
        .s_out(s_lev5),
        .c_out(c_lev5)
    );
    
    dadda_compressor_stage6 stage6 (
        .s_in(s_lev5),
        .c_in(c_lev5),
        .s_out(s_lev6),
        .c_out(c_lev6)
    );
    
    // 最终加法器（组合逻辑）
    assign p = s_lev6 + {c_lev6[46:0], 1'b0};
endmodule

// Dadda压缩树各阶段模块（纯组合逻辑）
module dadda_compressor_stage1 (
    input [23:0] pp [23:0],
    output [47:0] s,
    output [47:0] c
);
    // 组合逻辑实现
    assign s = 48'd0;
    assign c = 48'd0;
    // 实际实现需要根据Dadda压缩规则处理
endmodule

module dadda_compressor_stage2 (
    input [47:0] s_in,
    input [47:0] c_in,
    output [47:0] s_out,
    output [47:0] c_out
);
    // 组合逻辑实现
    assign s_out = s_in;
    assign c_out = c_in;
endmodule

module dadda_compressor_stage3 (
    input [47:0] s_in,
    input [47:0] c_in,
    output [47:0] s_out,
    output [47:0] c_out
);
    // 组合逻辑实现
    assign s_out = s_in;
    assign c_out = c_in;
endmodule

module dadda_compressor_stage4 (
    input [47:0] s_in,
    input [47:0] c_in,
    output [47:0] s_out,
    output [47:0] c_out
);
    // 组合逻辑实现
    assign s_out = s_in;
    assign c_out = c_in;
endmodule

module dadda_compressor_stage5 (
    input [47:0] s_in,
    input [47:0] c_in,
    output [47:0] s_out,
    output [47:0] c_out
);
    // 组合逻辑实现
    assign s_out = s_in;
    assign c_out = c_in;
endmodule

module dadda_compressor_stage6 (
    input [47:0] s_in,
    input [47:0] c_in,
    output [47:0] s_out,
    output [47:0] c_out
);
    // 组合逻辑实现
    assign s_out = s_in;
    assign c_out = c_in;
endmodule