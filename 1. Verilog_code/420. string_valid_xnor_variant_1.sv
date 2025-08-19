//SystemVerilog
module string_valid_xnor (a_valid, b_valid, data_a, data_b, out);
    input a_valid, b_valid;
    input wire [7:0] data_a, data_b;
    output reg [7:0] out;

    // 部分积生成
    wire [63:0] pp; // 部分积矩阵
    wire [15:0] product; // 乘法结果

    // 生成部分积
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen_pp_i
            for (j = 0; j < 8; j = j + 1) begin: gen_pp_j
                assign pp[i*8+j] = data_a[i] & data_b[j];
            end
        end
    endgenerate

    // Dadda乘法器的压缩树
    // 第一级压缩 (从高度6到高度4)
    wire [5:0] s1, c1; // 第一级和与进位
    wire [7:0] d1_0, d1_1, d1_2, d1_3; // 第一级压缩后的四行

    // 半加器和全加器组件
    wire [5:0] ha1_s, ha1_c; // 半加器输出
    wire [5:0] fa1_s, fa1_c; // 全加器输出

    // 第一级压缩：使用半加器和全加器
    assign ha1_s[0] = pp[6] ^ pp[14]; 
    assign ha1_c[0] = pp[6] & pp[14];
    
    assign fa1_s[0] = pp[7] ^ pp[15] ^ pp[23]; 
    assign fa1_c[0] = (pp[7] & pp[15]) | (pp[15] & pp[23]) | (pp[7] & pp[23]);
    
    assign fa1_s[1] = pp[16] ^ pp[24] ^ pp[32]; 
    assign fa1_c[1] = (pp[16] & pp[24]) | (pp[24] & pp[32]) | (pp[16] & pp[32]);
    
    assign fa1_s[2] = pp[25] ^ pp[33] ^ pp[41]; 
    assign fa1_c[2] = (pp[25] & pp[33]) | (pp[33] & pp[41]) | (pp[25] & pp[41]);
    
    assign fa1_s[3] = pp[34] ^ pp[42] ^ pp[50]; 
    assign fa1_c[3] = (pp[34] & pp[42]) | (pp[42] & pp[50]) | (pp[34] & pp[50]);
    
    assign ha1_s[1] = pp[43] ^ pp[51]; 
    assign ha1_c[1] = pp[43] & pp[51];

    // 第二级压缩 (从高度4到高度3)
    wire [7:0] d2_0, d2_1, d2_2; // 第二级压缩后的三行
    wire [7:0] ha2_s, ha2_c; // 半加器输出
    wire [7:0] fa2_s, fa2_c; // 全加器输出

    // 第二级压缩：使用半加器和全加器
    assign ha2_s[0] = pp[4] ^ pp[12]; 
    assign ha2_c[0] = pp[4] & pp[12];
    
    assign fa2_s[0] = pp[5] ^ pp[13] ^ ha1_s[0]; 
    assign fa2_c[0] = (pp[5] & pp[13]) | (pp[13] & ha1_s[0]) | (pp[5] & ha1_s[0]);
    
    assign fa2_s[1] = fa1_s[0] ^ pp[22] ^ pp[30]; 
    assign fa2_c[1] = (fa1_s[0] & pp[22]) | (pp[22] & pp[30]) | (fa1_s[0] & pp[30]);
    
    assign fa2_s[2] = fa1_s[1] ^ pp[31] ^ pp[39]; 
    assign fa2_c[2] = (fa1_s[1] & pp[31]) | (pp[31] & pp[39]) | (fa1_s[1] & pp[39]);
    
    assign fa2_s[3] = fa1_s[2] ^ pp[40] ^ pp[48]; 
    assign fa2_c[3] = (fa1_s[2] & pp[40]) | (pp[40] & pp[48]) | (fa1_s[2] & pp[48]);
    
    assign fa2_s[4] = fa1_s[3] ^ pp[49] ^ pp[57]; 
    assign fa2_c[4] = (fa1_s[3] & pp[49]) | (pp[49] & pp[57]) | (fa1_s[3] & pp[57]);
    
    assign ha2_s[1] = ha1_s[1] ^ pp[59]; 
    assign ha2_c[1] = ha1_s[1] & pp[59];

    // 第三级压缩 (从高度3到高度2)
    wire [15:0] d3_0, d3_1; // 最终两行
    wire [15:0] ha3_s, ha3_c; // 半加器输出
    wire [15:0] fa3_s, fa3_c; // 全加器输出

    // 最终的加法器
    assign d3_0[0] = pp[0];
    assign d3_0[1] = pp[1] ^ pp[8];
    assign d3_0[2] = pp[2] ^ pp[9] ^ pp[16];
    assign d3_0[3] = pp[3] ^ pp[10] ^ pp[17] ^ pp[24];
    assign d3_0[4] = ha2_s[0] ^ pp[20] ^ pp[28];
    assign d3_0[5] = fa2_s[0] ^ ha1_c[0] ^ pp[29];
    assign d3_0[6] = fa2_s[1] ^ fa1_c[0] ^ pp[38];
    assign d3_0[7] = fa2_s[2] ^ fa1_c[1] ^ pp[47];
    assign d3_0[8] = fa2_s[3] ^ fa1_c[2] ^ pp[56];
    assign d3_0[9] = fa2_s[4] ^ fa1_c[3] ^ ha1_c[1];
    assign d3_0[10] = ha2_s[1] ^ pp[58];
    assign d3_0[11] = pp[59];
    assign d3_0[12] = 0;
    assign d3_0[13] = 0;
    assign d3_0[14] = 0;
    assign d3_0[15] = 0;

    assign d3_1[0] = 0;
    assign d3_1[1] = pp[0] & pp[8];
    assign d3_1[2] = (pp[2] & pp[9]) | (pp[9] & pp[16]) | (pp[2] & pp[16]);
    assign d3_1[3] = (pp[3] & pp[10]) | (pp[10] & pp[17]) | (pp[3] & pp[17]) | (pp[17] & pp[24]) | (pp[3] & pp[24]) | (pp[10] & pp[24]);
    assign d3_1[4] = ha2_c[0] ^ pp[11] ^ pp[19] ^ pp[27];
    assign d3_1[5] = fa2_c[0] ^ pp[21] ^ pp[28];
    assign d3_1[6] = fa2_c[1] ^ ha2_c[0] ^ pp[37];
    assign d3_1[7] = fa2_c[2] ^ fa2_c[1] ^ pp[46];
    assign d3_1[8] = fa2_c[3] ^ fa2_c[2] ^ pp[55];
    assign d3_1[9] = fa2_c[4] ^ fa2_c[3] ^ fa1_c[3];
    assign d3_1[10] = ha2_c[1] ^ fa2_c[4];
    assign d3_1[11] = 0;
    assign d3_1[12] = 0;
    assign d3_1[13] = 0;
    assign d3_1[14] = 0;
    assign d3_1[15] = 0;

    // 最终的进位传递加法器
    assign product = d3_0 + d3_1;

    // 按原始接口规范输出结果
    always @(*) begin
        if (a_valid && b_valid) begin
            out = product[7:0]; // 取低8位作为输出
        end else begin
            out = 8'b0;
        end
    end
endmodule