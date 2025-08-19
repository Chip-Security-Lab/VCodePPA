//SystemVerilog
module subtractor_top #(parameter W=8) (
    input clk, en,
    input [W-1:0] a, b,
    output [W-1:0] diff_out
);
    reg [W-1:0] a_reg, b_reg;
    
    // 分离寄存器逻辑至独立always块
    always @(posedge clk) begin
        if (en) a_reg <= a;
    end
    
    always @(posedge clk) begin
        if (en) b_reg <= b;
    end
    
    // 并行前缀减法器实例
    parallel_prefix_subtractor #(.WIDTH(W)) sub_inst (
        .a(a_reg),
        .b(b_reg),
        .diff(diff_out)
    );
endmodule

// 并行前缀减法器模块
module parallel_prefix_subtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);
    wire [WIDTH-1:0] b_complement;
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] p, g;
    wire [WIDTH-1:0] p_stage1, g_stage1;
    wire [WIDTH-1:0] p_stage2, g_stage2;
    wire [WIDTH-1:0] p_stage3, g_stage3;
    
    // 取反加一 (二进制补码)
    assign b_complement = ~b + 1'b1;
    
    // 生成初始传播和生成信号
    assign p = a ^ b_complement;
    assign g = a & b_complement;
    
    // 第一阶段前缀计算模块
    prefix_stage1 #(.WIDTH(WIDTH)) stage1_inst (
        .p_in(p),
        .g_in(g),
        .p_out(p_stage1),
        .g_out(g_stage1)
    );
    
    // 第二阶段前缀计算模块
    prefix_stage2 #(.WIDTH(WIDTH)) stage2_inst (
        .p_in(p_stage1),
        .g_in(g_stage1),
        .p_out(p_stage2),
        .g_out(g_stage2)
    );
    
    // 第三阶段前缀计算模块
    prefix_stage3 #(.WIDTH(WIDTH)) stage3_inst (
        .p_in(p_stage2),
        .g_in(g_stage2),
        .p_out(p_stage3),
        .g_out(g_stage3)
    );
    
    // 计算进位信号
    assign carry[0] = 1'b1; // 减法初始进位为1
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: carry_gen
            assign carry[i+1] = g_stage3[i] | (p_stage3[i] & carry[i]);
        end
    endgenerate
    
    // 计算最终差值
    assign diff = p ^ carry[WIDTH-1:0];
endmodule

// 第一阶段: 2位并行前缀计算
module prefix_stage1 #(parameter WIDTH=8) (
    input [WIDTH-1:0] p_in,
    input [WIDTH-1:0] g_in,
    output [WIDTH-1:0] p_out,
    output [WIDTH-1:0] g_out
);
    genvar i;
    generate
        // 偶数位直接传递
        assign p_out[0] = p_in[0];
        assign g_out[0] = g_in[0];
        
        // 奇数位合并
        for (i = 1; i < WIDTH; i = i + 2) begin: odd_bits
            assign p_out[i] = p_in[i] & p_in[i-1];
            assign g_out[i] = g_in[i] | (p_in[i] & g_in[i-1]);
            
            if (i+1 < WIDTH) begin: even_bits
                assign p_out[i+1] = p_in[i+1];
                assign g_out[i+1] = g_in[i+1];
            end
        end
    endgenerate
endmodule

// 第二阶段: 4位并行前缀计算
module prefix_stage2 #(parameter WIDTH=8) (
    input [WIDTH-1:0] p_in,
    input [WIDTH-1:0] g_in,
    output [WIDTH-1:0] p_out,
    output [WIDTH-1:0] g_out
);
    genvar i;
    generate
        // 处理每4位中的位3
        for (i = 3; i < WIDTH; i = i + 4) begin: bit3_proc
            assign p_out[i] = p_in[i] & p_in[i-2];
            assign g_out[i] = g_in[i] | (p_in[i] & g_in[i-2]);
            
            // 保持其他位不变
            if (i-1 >= 0) begin: bit2_pass
                assign p_out[i-1] = p_in[i-1];
                assign g_out[i-1] = g_in[i-1];
            end
            
            if (i-2 >= 0) begin: bit1_pass
                assign p_out[i-2] = p_in[i-2];
                assign g_out[i-2] = g_in[i-2];
            end
            
            if (i-3 >= 0) begin: bit0_pass
                assign p_out[i-3] = p_in[i-3];
                assign g_out[i-3] = g_in[i-3];
            end
        end
        
        // 填充剩余位
        for (i = 0; i < WIDTH; i = i + 4) begin: fill_remaining
            if (i < WIDTH && (i % 4) == 0) begin: bit0_fill
                assign p_out[i] = p_in[i];
                assign g_out[i] = g_in[i];
            end
        end
    endgenerate
endmodule

// 第三阶段: 8位并行前缀计算
module prefix_stage3 #(parameter WIDTH=8) (
    input [WIDTH-1:0] p_in,
    input [WIDTH-1:0] g_in,
    output [WIDTH-1:0] p_out,
    output [WIDTH-1:0] g_out
);
    genvar i;
    generate
        if (WIDTH >= 8) begin: width_ge_8
            // 处理每8位中的位7
            for (i = 7; i < WIDTH; i = i + 8) begin: bit7_proc
                assign p_out[i] = p_in[i] & p_in[i-4];
                assign g_out[i] = g_in[i] | (p_in[i] & g_in[i-4]);
                
                // 保持其他位不变
                if (i-1 >= 0) begin: bit6_pass
                    assign p_out[i-1] = p_in[i-1];
                    assign g_out[i-1] = g_in[i-1];
                end
                if (i-2 >= 0) begin: bit5_pass
                    assign p_out[i-2] = p_in[i-2];
                    assign g_out[i-2] = g_in[i-2];
                end
                if (i-3 >= 0) begin: bit4_pass
                    assign p_out[i-3] = p_in[i-3];
                    assign g_out[i-3] = g_in[i-3];
                end
                if (i-4 >= 0) begin: bit3_pass
                    assign p_out[i-4] = p_in[i-4];
                    assign g_out[i-4] = g_in[i-4];
                end
                if (i-5 >= 0) begin: bit2_pass
                    assign p_out[i-5] = p_in[i-5];
                    assign g_out[i-5] = g_in[i-5];
                end
                if (i-6 >= 0) begin: bit1_pass
                    assign p_out[i-6] = p_in[i-6];
                    assign g_out[i-6] = g_in[i-6];
                end
                if (i-7 >= 0) begin: bit0_pass
                    assign p_out[i-7] = p_in[i-7];
                    assign g_out[i-7] = g_in[i-7];
                end
            end
            
            // 填充最低7位
            for (i = 0; i < 7 && i < WIDTH; i = i + 1) begin: low_bits_fill
                assign p_out[i] = p_in[i];
                assign g_out[i] = g_in[i];
            end
        end
        else begin: width_lt_8
            // WIDTH<8时直接传递
            for (i = 0; i < WIDTH; i = i + 1) begin: bypass
                assign p_out[i] = p_in[i];
                assign g_out[i] = g_in[i];
            end
        end
    endgenerate
endmodule