//SystemVerilog
module Demux_Priority #(parameter DW=4) (
    input [DW-1:0] data_in,
    input [3:0] sel,
    output reg [15:0][DW-1:0] data_out
);
    // 使用Brent-Kung加法器处理输入数据
    wire [DW-1:0] processed_data;
    BrentKungAdder #(.WIDTH(DW)) bk_adder (
        .a(data_in),
        .b({DW{1'b1}}),  // 加1操作
        .cin(1'b0),
        .sum(processed_data),
        .cout()
    );
    
    always @(*) begin
        // 初始化输出为零
        for (integer i = 0; i < 16; i = i + 1) begin
            data_out[i] = {DW{1'b0}};
        end
        
        // 使用if-else结构替代casez，根据优先级解码
        if (sel[3] == 1'b1) begin
            // 优先级最高：sel[3] = 1
            data_out[15] = processed_data;
        end
        else if (sel[2] == 1'b1) begin
            // 第二优先级：sel = 01xx
            data_out[7] = processed_data;
        end
        else if (sel[1] == 1'b1) begin
            // 第三优先级：sel = 001x
            data_out[3] = processed_data;
        end
        else if (sel[0] == 1'b1) begin
            // 第四优先级：sel = 0001
            data_out[1] = processed_data;
        end
        else begin
            // 默认情况：sel = 0000
            data_out[0] = processed_data;
        end
    end
endmodule

// Brent-Kung加法器实现 (16位)
module BrentKungAdder #(parameter WIDTH=16) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    // 生成(G)和传播(P)信号
    wire [WIDTH-1:0] G, P;
    wire [WIDTH:0] C;
    
    // 第一阶段：计算位生成和传播
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp
            assign G[i] = a[i] & b[i];
            assign P[i] = a[i] | b[i];
        end
    endgenerate
    
    // 初始进位
    assign C[0] = cin;
    
    // 第二阶段：Brent-Kung树形结构计算进位
    wire [WIDTH-1:0] G_temp, P_temp;
    
    // 第一级：2个位一组
    generate
        for (i = 0; i < WIDTH; i = i + 2) begin : level1
            if (i+1 < WIDTH) begin
                assign G_temp[i] = G[i] | (P[i] & G[i+1]);
                assign P_temp[i] = P[i] & P[i+1];
            end else begin
                assign G_temp[i] = G[i];
                assign P_temp[i] = P[i];
            end
        end
    endgenerate
    
    // 第二级：4个位一组
    wire [WIDTH-1:0] G_temp2, P_temp2;
    generate
        for (i = 0; i < WIDTH; i = i + 4) begin : level2
            if (i+2 < WIDTH) begin
                assign G_temp2[i] = G_temp[i] | (P_temp[i] & G_temp[i+2]);
                assign P_temp2[i] = P_temp[i] & P_temp[i+2];
            end else begin
                assign G_temp2[i] = G_temp[i];
                assign P_temp2[i] = P_temp[i];
            end
        end
    endgenerate
    
    // 第三级：8个位一组
    wire [WIDTH-1:0] G_temp3, P_temp3;
    generate
        for (i = 0; i < WIDTH; i = i + 8) begin : level3
            if (i+4 < WIDTH) begin
                assign G_temp3[i] = G_temp2[i] | (P_temp2[i] & G_temp2[i+4]);
                assign P_temp3[i] = P_temp2[i] & P_temp2[i+4];
            end else begin
                assign G_temp3[i] = G_temp2[i];
                assign P_temp3[i] = P_temp2[i];
            end
        end
    endgenerate
    
    // 第四级：16个位一组
    wire [WIDTH-1:0] G_temp4, P_temp4;
    generate
        for (i = 0; i < WIDTH; i = i + 16) begin : level4
            if (i+8 < WIDTH) begin
                assign G_temp4[i] = G_temp3[i] | (P_temp3[i] & G_temp3[i+8]);
                assign P_temp4[i] = P_temp3[i] & P_temp3[i+8];
            end else begin
                assign G_temp4[i] = G_temp3[i];
                assign P_temp4[i] = P_temp3[i];
            end
        end
    endgenerate
    
    // 反向传播计算所有进位
    assign C[1] = G[0] | (P[0] & C[0]);
    
    generate
        for (i = 2; i <= WIDTH; i = i + 1) begin : gen_carry
            if (i % 16 == 0) begin
                assign C[i] = G_temp4[i-16] | (P_temp4[i-16] & C[i-16]);
            end else if (i % 8 == 0) begin
                assign C[i] = G_temp3[i-8] | (P_temp3[i-8] & C[i-8]);
            end else if (i % 4 == 0) begin
                assign C[i] = G_temp2[i-4] | (P_temp2[i-4] & C[i-4]);
            end else if (i % 2 == 0) begin
                assign C[i] = G_temp[i-2] | (P_temp[i-2] & C[i-2]);
            end else begin
                assign C[i] = G[i-1] | (P[i-1] & C[i-1]);
            end
        end
    endgenerate
    
    // 第三阶段：计算最终的和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = a[i] ^ b[i] ^ C[i];
        end
    endgenerate
    
    // 输出进位
    assign cout = C[WIDTH];
endmodule