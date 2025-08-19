//SystemVerilog
module weighted_fuzzy_comparator #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] WEIGHT_MASK = 8'b11110000  // MSBs have higher weight
)(
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output match_high_significance,  // Match considering only high significance bits
    output match_low_significance,   // Match considering only low significance bits 
    output match_all,                // Match on all bits
    output [3:0] similarity_score    // 0-10 score representing similarity
);
    // Split the comparison based on significance
    wire [WIDTH-1:0] difference = data_a ^ data_b;
    wire [WIDTH-1:0] high_sig_diff = difference & WEIGHT_MASK;
    wire [WIDTH-1:0] low_sig_diff = difference & ~WEIGHT_MASK;
    
    // Match flags
    assign match_high_significance = (high_sig_diff == {WIDTH{1'b0}});
    assign match_low_significance = (low_sig_diff == {WIDTH{1'b0}});
    assign match_all = match_high_significance && match_low_significance;
    
    // Calculate similarity score (0-10)
    // More weight given to high significance bits
    wire [5:0] weighted_match;
    
    // 预先计算WEIGHT_MASK中1的个数
    function integer count_ones;
        input [WIDTH-1:0] data;
        integer i, count;
        begin
            count = 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (data[i]) count = count + 1;
            end
            count_ones = count;
        end
    endfunction
    
    // 编译时计算除数
    localparam DIVISOR = 2 * count_ones(WEIGHT_MASK) + (WIDTH - count_ones(WEIGHT_MASK));
    
    // 使用带状进位加法器计算weighted_match
    // 为每个匹配的位计算权重和
    wire [5:0] match_weights[WIDTH-1:0];
    wire [5:0] partial_sums[WIDTH:0];
    wire [WIDTH:0] carry_propagate, carry_generate;
    wire [WIDTH:0] carries;
    
    // 初始条件
    assign partial_sums[0] = 6'd0;
    assign carries[0] = 1'b0;
    
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin: match_weight_gen
            // 计算每位的权重
            assign match_weights[j] = !difference[j] ? 
                                     (WEIGHT_MASK[j] ? 6'd2 : 6'd1) : 
                                     6'd0;
            
            // 生成p和g信号（用于CLA加法器）
            assign carry_propagate[j] = partial_sums[j][0] | match_weights[j][0];
            assign carry_generate[j] = partial_sums[j][0] & match_weights[j][0];
            
            // CLA逻辑
            if (j % 2 == 0) begin: even_bits
                assign carries[j+1] = carry_generate[j] | (carry_propagate[j] & carries[j]);
            end else begin: odd_bits
                // 对奇数位使用更复杂的CLA逻辑以创建带状进位结构
                assign carries[j+1] = carry_generate[j] | 
                                    (carry_propagate[j] & carry_generate[j-1]) |
                                    (carry_propagate[j] & carry_propagate[j-1] & carries[j-1]);
            end
            
            // 计算每一位的和
            assign partial_sums[j+1] = partial_sums[j] + match_weights[j] + {5'd0, carries[j]};
        end
    endgenerate
    
    // 最终结果
    assign weighted_match = partial_sums[WIDTH];
    
    // Scale to 0-10 range
    wire [11:0] product;
    cla_multiplier #(.WIDTH(6)) mult (
        .a(weighted_match),
        .b(6'd10),
        .product(product)
    );
    
    assign similarity_score = product / DIVISOR;
endmodule

// 带状进位乘法器模块
module cla_multiplier #(
    parameter WIDTH = 6
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [2*WIDTH-1:0] product
);
    wire [2*WIDTH-1:0] partial_products [WIDTH-1:0];
    wire [2*WIDTH-1:0] sum [WIDTH-1:0];
    wire [WIDTH:0] carries;
    
    // 初始化
    assign carries[0] = 1'b0;
    assign sum[0] = {2*WIDTH{1'b0}};
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: mult_stage
            // 创建部分积
            assign partial_products[i] = b[i] ? (a << i) : {2*WIDTH{1'b0}};
            
            // 使用带状进位加法器进行累加
            wire [2*WIDTH-1:0] p; // 传播信号
            wire [2*WIDTH-1:0] g; // 生成信号
            
            assign p = sum[i] ^ partial_products[i];
            assign g = sum[i] & partial_products[i];
            
            if (i < 3) begin: first_level_cla
                // 前3位使用简单CLA
                wire [2*WIDTH-1:0] c;
                assign c[0] = carries[i];
                
                genvar k;
                for (k = 0; k < 2*WIDTH-1; k = k + 1) begin: carry_chain
                    assign c[k+1] = g[k] | (p[k] & c[k]);
                end
                
                assign sum[i+1] = p ^ c;
                assign carries[i+1] = c[2*WIDTH-1];
            end else begin: multilevel_cla
                // 后续位使用分层CLA结构
                wire [2*WIDTH-1:0] c;
                assign c[0] = carries[i];
                
                // 分组CLA
                genvar k;
                for (k = 0; k < 2*WIDTH/2; k = k + 1) begin: group_cla
                    wire [1:0] group_p;
                    wire [1:0] group_g;
                    wire [2:0] group_c;
                    
                    assign group_p[0] = p[k*2];
                    assign group_p[1] = p[k*2+1];
                    assign group_g[0] = g[k*2];
                    assign group_g[1] = g[k*2+1];
                    
                    assign group_c[0] = (k == 0) ? carries[i] : c[k*2-1];
                    assign group_c[1] = group_g[0] | (group_p[0] & group_c[0]);
                    assign group_c[2] = group_g[1] | (group_p[1] & group_c[1]);
                    
                    assign c[k*2] = group_c[1];
                    assign c[k*2+1] = group_c[2];
                end
                
                assign sum[i+1] = p ^ c;
                assign carries[i+1] = c[2*WIDTH-1];
            end
        end
    endgenerate
    
    assign product = sum[WIDTH];
endmodule