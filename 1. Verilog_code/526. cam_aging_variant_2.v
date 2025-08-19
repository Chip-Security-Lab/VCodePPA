module cam_aging #(parameter WIDTH=8, DEPTH=16, AGING_BITS=4)(
    input clk,
    input rst_n,  // 添加复位信号
    input [WIDTH-1:0] data_in,
    input search_en,
    input data_valid,  // 流水线控制信号
    output reg data_valid_out,  // 流水线输出有效信号
    output reg [DEPTH-1:0] match_hits
);
    // 寄存器定义
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    reg [AGING_BITS-1:0] age_counters [0:DEPTH-1];
    
    // 流水线阶段寄存器
    reg [WIDTH-1:0] data_in_stage1, data_in_stage2;
    reg search_en_stage1, search_en_stage2;
    reg data_valid_stage1, data_valid_stage2;
    reg [DEPTH-1:0] match_results_stage1, match_results_stage2;
    
    // 阶段1: Han-Carlson 加法器的结果
    wire [AGING_BITS-1:0] inc_result [0:DEPTH-1];
    wire [AGING_BITS-1:0] dec_result [0:DEPTH-1];
    
    // 阶段2: 匹配结果计算
    reg [DEPTH-1:0] match_condition [0:1];
    reg [AGING_BITS-1:0] age_counters_stage1 [0:DEPTH-1];
    
    // 流水线控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_stage1 <= 1'b0;
            data_valid_stage2 <= 1'b0;
            data_valid_out <= 1'b0;
        end else begin
            data_valid_stage1 <= data_valid;
            data_valid_stage2 <= data_valid_stage1;
            data_valid_out <= data_valid_stage2;
        end
    end
    
    // 第一级流水线 - 数据捕获和初始计算
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= {WIDTH{1'b0}};
            search_en_stage1 <= 1'b0;
            for (i=0; i<DEPTH; i=i+1) begin
                match_condition[0][i] <= 1'b0;
                age_counters_stage1[i] <= {AGING_BITS{1'b0}};
            end
        end else if (data_valid) begin
            data_in_stage1 <= data_in;
            search_en_stage1 <= search_en;
            for (i=0; i<DEPTH; i=i+1) begin
                match_condition[0][i] <= (data_in == entries[i]);
                age_counters_stage1[i] <= age_counters[i];
            end
        end
    end
    
    // 第二级流水线 - 计算匹配结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage2 <= {WIDTH{1'b0}};
            search_en_stage2 <= 1'b0;
            for (i=0; i<DEPTH; i=i+1) begin
                match_condition[1][i] <= 1'b0;
                match_results_stage1[i] <= 1'b0;
            end
        end else if (data_valid_stage1) begin
            data_in_stage2 <= data_in_stage1;
            search_en_stage2 <= search_en_stage1;
            for (i=0; i<DEPTH; i=i+1) begin
                match_condition[1][i] <= match_condition[0][i];
                match_results_stage1[i] <= search_en_stage1 && 
                                          match_condition[0][i] && 
                                          (age_counters_stage1[i] > {(AGING_BITS){1'b0}});
            end
        end
    end
    
    // 第三级流水线 - 最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_hits <= {DEPTH{1'b0}};
            match_results_stage2 <= {DEPTH{1'b0}};
        end else if (data_valid_stage2) begin
            match_hits <= match_results_stage1;
            match_results_stage2 <= match_results_stage1;
        end
    end
    
    // 更新年龄计数器逻辑（在流水线结束后执行）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<DEPTH; i=i+1) begin
                age_counters[i] <= {AGING_BITS{1'b0}};
            end
        end else if (data_valid_stage2) begin
            for (i=0; i<DEPTH; i=i+1) begin
                if (search_en_stage2 && match_condition[1][i])
                    age_counters[i] <= inc_result[i];
                else if (age_counters[i] > {(AGING_BITS){1'b0}})
                    age_counters[i] <= dec_result[i];
            end
        end
    end
    
    // Han-Carlson adder implementation - 保持并行计算
    genvar j;
    generate
        for (j=0; j<DEPTH; j=j+1) begin: adder_gen
            // Increment adder
            pipelined_han_carlson_adder #(.WIDTH(AGING_BITS)) inc_adder (
                .clk(clk),
                .rst_n(rst_n),
                .a(age_counters[j]),
                .b({{(AGING_BITS-1){1'b0}}, 1'b1}),
                .sum(inc_result[j])
            );
            
            // Decrement adder
            pipelined_han_carlson_adder #(.WIDTH(AGING_BITS)) dec_adder (
                .clk(clk),
                .rst_n(rst_n),
                .a(age_counters[j]),
                .b({(AGING_BITS){1'b1}}),
                .sum(dec_result[j])
            );
        end
    endgenerate
endmodule

module pipelined_han_carlson_adder #(parameter WIDTH=4)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output reg [WIDTH-1:0] sum
);
    // 第一级流水线寄存器
    reg [WIDTH-1:0] a_stage1, b_stage1;
    reg [WIDTH-1:0] g_stage1, p_stage1;
    
    // 第二级流水线寄存器
    reg [WIDTH-1:0] g_stage2, p_stage2;
    reg [WIDTH-1:0] p_mid_stage2;
    
    // 第三级流水线寄存器
    reg [WIDTH-1:0] g_stage3, p_stage3;
    
    // 第一级流水线 - 预计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= {WIDTH{1'b0}};
            b_stage1 <= {WIDTH{1'b0}};
            g_stage1 <= {WIDTH{1'b0}};
            p_stage1 <= {WIDTH{1'b0}};
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            g_stage1 <= a & b;                  // 生成位
            p_stage1 <= a ^ b;                  // 传播位
        end
    end
    
    // 第二级流水线 - 第一阶段合并
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage2 <= {WIDTH{1'b0}};
            p_stage2 <= {WIDTH{1'b0}};
            p_mid_stage2 <= {WIDTH{1'b0}};
        end else begin
            // 第一级生成和传播
            g_stage2[0] <= g_stage1[0];
            p_stage2[0] <= p_stage1[0];
            
            if (WIDTH > 1) begin
                g_stage2[1] <= g_stage1[1] | (p_stage1[1] & g_stage1[0]);
                p_stage2[1] <= p_stage1[1] & p_stage1[0];
            end
            
            // 保存原始传播位用于最终求和
            p_mid_stage2 <= p_stage1;
        end
    end
    
    // 第三级流水线 - 第二阶段合并
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage3 <= {WIDTH{1'b0}};
            p_stage3 <= {WIDTH{1'b0}};
        end else begin
            g_stage3[0] <= g_stage2[0];
            p_stage3[0] <= p_stage2[0];
            
            if (WIDTH > 1) begin
                g_stage3[1] <= g_stage2[1];
                p_stage3[1] <= p_stage2[1];
            end
            
            if (WIDTH > 2) begin
                g_stage3[2] <= g_stage1[2] | (p_stage1[2] & g_stage2[1]);
                p_stage3[2] <= p_stage1[2] & p_stage2[1];
            end
            
            if (WIDTH > 3) begin
                g_stage3[3] <= g_stage1[3] | (p_stage1[3] & g_stage1[2]) | 
                              (p_stage1[3] & p_stage1[2] & g_stage2[1]);
                p_stage3[3] <= p_stage1[3] & p_stage1[2] & p_stage2[1];
            end
        end
    end
    
    // 第四级流水线 - 最终计算结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= {WIDTH{1'b0}};
        end else begin
            sum[0] <= p_mid_stage2[0];
            
            if (WIDTH > 1)
                sum[1] <= p_mid_stage2[1] ^ g_stage3[0];
            
            if (WIDTH > 2)
                sum[2] <= p_mid_stage2[2] ^ g_stage3[1];
            
            if (WIDTH > 3)
                sum[3] <= p_mid_stage2[3] ^ g_stage3[2];
        end
    end
endmodule