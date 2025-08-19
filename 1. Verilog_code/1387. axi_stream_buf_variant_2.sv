//SystemVerilog
module axi_stream_buf #(parameter DW=64) (
    input clk, rst_n,
    input tvalid_in, tready_out,
    output tvalid_out, tready_in,
    input [DW-1:0] tdata_in,
    output [DW-1:0] tdata_out
);
    reg [DW-1:0] buf_reg;
    reg buf_valid = 0;
    wire [7:0] subtractor_out;
    
    // 原始缓冲区逻辑
    assign tready_in = ~buf_valid;
    assign tvalid_out = buf_valid;
    
    // 将8位并行前缀减法器应用于输入数据的低8位
    parallel_prefix_subtractor u_subtractor (
        .a(tdata_in[7:0]),
        .b(8'h01),  // 减去常数1
        .diff(subtractor_out)
    );
    
    // 合并减法器输出与其他数据位
    assign tdata_out = {buf_reg[DW-1:8], subtractor_out};
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) buf_valid <= 0;
        else begin
            if(tvalid_in && tready_in) begin
                buf_reg <= tdata_in;
                buf_valid <= 1;
            end
            else if(tready_out && buf_valid)
                buf_valid <= 0;
        end
    end
endmodule

// 8位并行前缀减法器模块
module parallel_prefix_subtractor (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff
);
    // 生成和传播信号
    wire [7:0] g, p;
    wire [7:0] c;
    
    // 第一阶段：计算传播和生成位
    assign p = a ^ b;        // 传播位
    assign g = (~a) & b;     // 生成位
    
    // 第二阶段：并行前缀计算进位
    // 级别1
    wire [7:0] g_l1, p_l1;
    
    assign g_l1[0] = g[0];
    assign p_l1[0] = p[0];
    
    generate
        genvar i;
        for (i = 1; i < 8; i = i + 1) begin : prefix_level1
            assign g_l1[i] = g[i] | (p[i] & g[i-1]);
            assign p_l1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // 级别2
    wire [7:0] g_l2, p_l2;
    
    assign g_l2[0] = g_l1[0];
    assign p_l2[0] = p_l1[0];
    assign g_l2[1] = g_l1[1];
    assign p_l2[1] = p_l1[1];
    
    generate
        for (i = 2; i < 8; i = i + 1) begin : prefix_level2
            assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
            assign p_l2[i] = p_l1[i] & p_l1[i-2];
        end
    endgenerate
    
    // 级别3（最终级别）
    wire [7:0] g_l3, p_l3;
    
    assign g_l3[0] = g_l2[0];
    assign p_l3[0] = p_l2[0];
    assign g_l3[1] = g_l2[1];
    assign p_l3[1] = p_l2[1];
    assign g_l3[2] = g_l2[2];
    assign p_l3[2] = p_l2[2];
    assign g_l3[3] = g_l2[3];
    assign p_l3[3] = p_l2[3];
    
    generate
        for (i = 4; i < 8; i = i + 1) begin : prefix_level3
            assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i-4]);
            assign p_l3[i] = p_l2[i] & p_l2[i-4];
        end
    endgenerate
    
    // 计算进位
    assign c[0] = 1'b1;  // 减法初始进位设为1
    generate
        for (i = 1; i < 8; i = i + 1) begin : carry_gen
            assign c[i] = g_l3[i-1] | (p_l3[i-1] & c[0]);
        end
    endgenerate
    
    // 第三阶段：计算差值
    assign diff = p ^ c;
    
endmodule