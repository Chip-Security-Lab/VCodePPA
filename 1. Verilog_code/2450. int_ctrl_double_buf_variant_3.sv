//SystemVerilog
module int_ctrl_double_buf #(WIDTH=8) (
    input clk, swap,
    input [WIDTH-1:0] new_status,
    output [WIDTH-1:0] current_status
);
    reg [WIDTH-1:0] buf1, buf2;
    wire [WIDTH-1:0] subtraction_result;
    reg [WIDTH-1:0] new_status_reg;  // 新增的输入寄存器
    
    // 将输入寄存器移到前端
    always @(posedge clk) begin
        new_status_reg <= new_status;
        
        if(swap) buf1 <= subtraction_result;
        else buf1 <= buf1;
        buf2 <= new_status_reg;
    end
    
    // 实例化并行前缀减法器
    parallel_prefix_subtractor #(.WIDTH(WIDTH)) subtractor_inst (
        .a(buf1),
        .b(new_status_reg),  // 使用寄存器化的输入
        .diff(subtraction_result)
    );
    
    assign current_status = buf1;
endmodule

// 并行前缀减法器模块
module parallel_prefix_subtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);
    wire [WIDTH-1:0] b_complement;
    wire [WIDTH:0] p_signals, g_signals;
    wire [WIDTH:0] carry;
    
    // 计算b的2的补码 (取反加1)
    assign b_complement = ~b + 1'b1;
    
    // 使用并行前缀算法计算减法 (通过加法实现)
    // 初始化传播和生成信号
    assign p_signals[0] = 1'b0;
    assign g_signals[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg_signals
            assign p_signals[i+1] = a[i] ^ b_complement[i];
            assign g_signals[i+1] = a[i] & b_complement[i];
        end
    endgenerate
    
    // 第1级前缀计算
    wire [WIDTH:0] p_level1, g_level1;
    generate
        for (i = 0; i <= WIDTH; i = i + 2) begin: gen_level1
            if (i == 0) begin
                assign p_level1[i] = p_signals[i];
                assign g_level1[i] = g_signals[i];
            end else if (i < WIDTH) begin
                assign p_level1[i] = p_signals[i] & p_signals[i-1];
                assign g_level1[i] = g_signals[i] | (p_signals[i] & g_signals[i-1]);
                assign p_level1[i+1] = p_signals[i+1];
                assign g_level1[i+1] = g_signals[i+1];
            end else if (i == WIDTH) begin
                assign p_level1[i] = p_signals[i];
                assign g_level1[i] = g_signals[i];
            end
        end
    endgenerate
    
    // 第2级前缀计算
    wire [WIDTH:0] p_level2, g_level2;
    generate
        for (i = 0; i <= WIDTH; i = i + 4) begin: gen_level2
            if (i == 0) begin
                assign p_level2[i] = p_level1[i];
                assign g_level2[i] = g_level1[i];
                if (i+1 <= WIDTH) begin
                    assign p_level2[i+1] = p_level1[i+1];
                    assign g_level2[i+1] = g_level1[i+1];
                end
            end else if (i < WIDTH) begin
                assign p_level2[i] = p_level1[i] & p_level1[i-2];
                assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
                if (i+1 <= WIDTH) begin
                    assign p_level2[i+1] = p_level1[i+1] & p_level1[i-1];
                    assign g_level2[i+1] = g_level1[i+1] | (p_level1[i+1] & g_level1[i-1]);
                end
                if (i+2 <= WIDTH) begin
                    assign p_level2[i+2] = p_level1[i+2];
                    assign g_level2[i+2] = g_level1[i+2];
                end
                if (i+3 <= WIDTH) begin
                    assign p_level2[i+3] = p_level1[i+3];
                    assign g_level2[i+3] = g_level1[i+3];
                end
            end else if (i == WIDTH) begin
                assign p_level2[i] = p_level1[i] & p_level1[i-2];
                assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
            end
        end
    endgenerate
    
    // 第3级前缀计算 (如果WIDTH=8，则需要第3级)
    wire [WIDTH:0] p_level3, g_level3;
    generate
        for (i = 0; i <= WIDTH; i = i + 8) begin: gen_level3
            if (i == 0) begin
                assign p_level3[i] = p_level2[i];
                assign g_level3[i] = g_level2[i];
                if (i+1 <= WIDTH) begin
                    assign p_level3[i+1] = p_level2[i+1];
                    assign g_level3[i+1] = g_level2[i+1];
                end
                if (i+2 <= WIDTH) begin
                    assign p_level3[i+2] = p_level2[i+2];
                    assign g_level3[i+2] = g_level2[i+2];
                end
                if (i+3 <= WIDTH) begin
                    assign p_level3[i+3] = p_level2[i+3];
                    assign g_level3[i+3] = g_level2[i+3];
                end
            end else if (i < WIDTH) begin
                assign p_level3[i] = p_level2[i] & p_level2[i-4];
                assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
                if (i+1 <= WIDTH) begin
                    assign p_level3[i+1] = p_level2[i+1] & p_level2[i-3];
                    assign g_level3[i+1] = g_level2[i+1] | (p_level2[i+1] & g_level2[i-3]);
                end
                if (i+2 <= WIDTH) begin
                    assign p_level3[i+2] = p_level2[i+2] & p_level2[i-2];
                    assign g_level3[i+2] = g_level2[i+2] | (p_level2[i+2] & g_level2[i-2]);
                end
                if (i+3 <= WIDTH) begin
                    assign p_level3[i+3] = p_level2[i+3] & p_level2[i-1];
                    assign g_level3[i+3] = g_level2[i+3] | (p_level2[i+3] & g_level2[i-1]);
                end
            end else if (i == WIDTH) begin
                assign p_level3[i] = p_level2[i] & p_level2[i-4];
                assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
            end
        end
    endgenerate
    
    // 计算进位
    assign carry[0] = 1'b0; // 减法的初始借位为0
    
    generate
        for (i = 1; i <= WIDTH; i = i + 1) begin: gen_carry
            assign carry[i] = g_level3[i];
        end
    endgenerate
    
    // 计算最终差值
    wire [WIDTH-1:0] diff_temp;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_diff
            assign diff_temp[i] = p_signals[i+1] ^ carry[i];
        end
    endgenerate
    
    assign diff = diff_temp;
endmodule