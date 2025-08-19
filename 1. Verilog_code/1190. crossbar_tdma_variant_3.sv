//SystemVerilog
`timescale 1ns / 1ps

//---------------------------------------------------------
// 顶层模块 - TDMA交叉开关控制器
//---------------------------------------------------------
module crossbar_tdma #(
    parameter DW = 8,       // 数据宽度
    parameter N = 4         // 输入/输出端口数
) (
    input wire clk,
    input wire [31:0] global_time,
    input wire [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout
);
    // 从全局时间中提取时隙信息
    wire [31:0] time_slot_full;
    wire [1:0] time_slot;
    
    // 时隙计算器实例化
    time_slot_calculator #(
        .WIDTH(32)
    ) time_slot_calc_inst (
        .global_time(global_time),
        .time_slot_full(time_slot_full)
    );
    
    // 提取时隙ID
    assign time_slot = time_slot_full[27:26];
    
    // 数据路由器实例化
    data_router #(
        .DW(DW),
        .N(N)
    ) router_inst (
        .clk(clk),
        .time_slot(time_slot),
        .din(din),
        .dout(dout)
    );
endmodule

//---------------------------------------------------------
// 时隙计算器模块 - 使用先行进位加法器处理时隙计算
//---------------------------------------------------------
module time_slot_calculator #(
    parameter WIDTH = 32
) (
    input wire [WIDTH-1:0] global_time,
    output wire [WIDTH-1:0] time_slot_full
);
    // 该模块可以进行更复杂的时隙计算，但当前实现只是传递global_time
    carry_lookahead_adder #(
        .WIDTH(WIDTH)
    ) cla_inst (
        .a(global_time),
        .b({WIDTH{1'b0}}),  // 这里可以进行时隙偏移或其他操作
        .cin(1'b0),
        .sum(time_slot_full),
        .cout()  // 不使用进位输出
    );
endmodule

//---------------------------------------------------------
// 数据路由器模块 - 根据时隙将数据从输入路由到输出
//---------------------------------------------------------
module data_router #(
    parameter DW = 8,
    parameter N = 4
) (
    input wire clk,
    input wire [1:0] time_slot,
    input wire [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout
);
    integer i;
    
    always @(posedge clk) begin
        // 重置所有输出为零
        for (i = 0; i < N; i = i + 1) begin
            dout[i] <= {DW{1'b0}};
        end
        
        // 根据当前时隙路由数据
        if (time_slot < N) begin
            for (i = 0; i < N; i = i + 1) begin
                // 将当前时隙的数据路由到所有输出
                dout[i] <= din[time_slot];
            end
        end
    end
endmodule

//---------------------------------------------------------
// 先行进位加法器模块 - 优化的32位加法器
//---------------------------------------------------------
module carry_lookahead_adder #(
    parameter WIDTH = 32
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    // 使用子模块处理进位生成和传播
    wire [WIDTH:0] c;
    wire [WIDTH-1:0] g, p;
    
    assign c[0] = cin;
    
    // 生成和传播信号计算模块
    generate_propagate_signals #(
        .WIDTH(WIDTH)
    ) gp_signals_inst (
        .a(a),
        .b(b),
        .g(g),
        .p(p)
    );
    
    // 进位计算模块
    carry_generator #(
        .WIDTH(WIDTH)
    ) carry_gen_inst (
        .g(g),
        .p(p),
        .cin(cin),
        .c(c)
    );
    
    // 求和模块
    sum_calculator #(
        .WIDTH(WIDTH)
    ) sum_calc_inst (
        .a(a),
        .b(b),
        .c(c[WIDTH-1:0]),
        .sum(sum)
    );
    
    // 输出最终进位
    assign cout = c[WIDTH];
endmodule

//---------------------------------------------------------
// 生成和传播信号计算模块
//---------------------------------------------------------
module generate_propagate_signals #(
    parameter WIDTH = 32
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] g,
    output wire [WIDTH-1:0] p
);
    // 生成进位产生(g)和进位传播(p)信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] | b[i];
        end
    endgenerate
endmodule

//---------------------------------------------------------
// 进位生成器模块 - 4位为一组的先行进位计算
//---------------------------------------------------------
module carry_generator #(
    parameter WIDTH = 32
) (
    input wire [WIDTH-1:0] g,
    input wire [WIDTH-1:0] p,
    input wire cin,
    output wire [WIDTH:0] c
);
    genvar i;
    
    assign c[0] = cin;
    
    // 4位为一组的先行进位逻辑
    generate
        for (i = 0; i < WIDTH; i = i + 4) begin : gen_cla_blocks
            // 处理每一组的先行进位
            if (i+4 <= WIDTH) begin
                // 创建4位CLA模块
                cla_block_4bit cla_block_inst (
                    .g(g[i+3:i]),
                    .p(p[i+3:i]),
                    .cin(c[i]),
                    .c(c[i+4:i+1])
                );
            end
        end
    endgenerate
endmodule

//---------------------------------------------------------
// 4位先行进位模块 - 处理一个4位组的先行进位计算
//---------------------------------------------------------
module cla_block_4bit (
    input wire [3:0] g,
    input wire [3:0] p,
    input wire cin,
    output wire [3:0] c
);
    // 计算当前组的进位链
    assign c[0] = g[0] | (p[0] & cin);
    assign c[1] = g[1] | (p[1] & c[0]);
    assign c[2] = g[2] | (p[2] & c[1]);
    assign c[3] = g[3] | (p[3] & c[2]);
endmodule

//---------------------------------------------------------
// 求和计算模块 - 计算最终的加法结果
//---------------------------------------------------------
module sum_calculator #(
    parameter WIDTH = 32
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire [WIDTH-1:0] c,
    output wire [WIDTH-1:0] sum
);
    // 计算每一位的和
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = a[i] ^ b[i] ^ c[i];
        end
    endgenerate
endmodule