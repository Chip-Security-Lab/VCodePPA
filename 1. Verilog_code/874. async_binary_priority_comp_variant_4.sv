//SystemVerilog
// 优先级掩码生成模块
module priority_mask_gen #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    output [WIDTH-1:0] priority_mask
);
    assign priority_mask[0] = data_vector[0];
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_priority
            assign priority_mask[i] = priority_mask[i-1] | data_vector[i];
        end
    endgenerate
endmodule

// 独热码生成模块
module one_hot_gen #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    input [WIDTH-1:0] priority_mask,
    output [WIDTH-1:0] one_hot
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_one_hot
            if (i == 0)
                assign one_hot[i] = data_vector[i];
            else
                assign one_hot[i] = data_vector[i] & ~priority_mask[i-1];
        end
    endgenerate
endmodule

// 索引选择模块
module index_selector #(parameter WIDTH = 8)(
    input [WIDTH-1:0] one_hot,
    output [$clog2(WIDTH)-1:0] selected_index
);
    assign selected_index = one_hot[1] ? 1 : 
                          one_hot[2] ? 2 : 
                          one_hot[3] ? 3 : 
                          one_hot[4] ? 4 : 
                          one_hot[5] ? 5 : 
                          one_hot[6] ? 6 : 
                          one_hot[7] ? 7 : 0;
endmodule

// Brent-Kung加法器前缀树模块
module bk_prefix_tree #(parameter WIDTH = 3)(
    input [WIDTH-1:0] g,
    input [WIDTH-1:0] p,
    output [WIDTH-1:0] g_out,
    output [WIDTH-1:0] p_out
);
    wire [WIDTH-1:0] g_prefix [0:$clog2(WIDTH)];
    wire [WIDTH-1:0] p_prefix [0:$clog2(WIDTH)];
    
    genvar i, j;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : init_prefix
            assign g_prefix[0][i] = g[i];
            assign p_prefix[0][i] = p[i];
        end
        
        for (i = 1; i <= $clog2(WIDTH); i = i + 1) begin : bk_forward
            for (j = (1 << i) - 1; j < WIDTH; j = j + (1 << i)) begin : bk_nodes
                assign g_prefix[i][j] = g_prefix[i-1][j] | 
                                      (p_prefix[i-1][j] & g_prefix[i-1][j - (1 << (i-1))]);
                assign p_prefix[i][j] = p_prefix[i-1][j] & p_prefix[i-1][j - (1 << (i-1))];
            end
        end
        
        for (i = $clog2(WIDTH) - 1; i >= 1; i = i - 1) begin : bk_backward
            for (j = (1 << i) + (1 << (i-1)) - 1; j < WIDTH; j = j + (1 << i)) begin : bk_fill
                assign g_prefix[$clog2(WIDTH)][j] = g_prefix[i-1][j] | 
                                                  (p_prefix[i-1][j] & g_prefix[$clog2(WIDTH)][j - (1 << (i-1))]);
                assign p_prefix[$clog2(WIDTH)][j] = p_prefix[i-1][j] & p_prefix[$clog2(WIDTH)][j - (1 << (i-1))];
            end
        end
        
        for (i = 0; i < WIDTH; i = i + 1) begin : assign_output
            assign g_out[i] = g_prefix[$clog2(WIDTH)][i];
            assign p_out[i] = p_prefix[$clog2(WIDTH)][i];
        end
    endgenerate
endmodule

// Brent-Kung加法器模块
module brent_kung_adder #(parameter WIDTH = 3)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] c;
    wire [WIDTH-1:0] g_out, p_out;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_init
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    assign c[0] = 1'b0;
    
    bk_prefix_tree #(WIDTH) prefix_tree(
        .g(g),
        .p(p),
        .g_out(g_out),
        .p_out(p_out)
    );
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
            if (i == 0)
                assign c[i+1] = g[i];
            else
                assign c[i+1] = g_out[i];
        end
    endgenerate
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
endmodule

// 顶层模块
module async_binary_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    output [$clog2(WIDTH)-1:0] encoded_output,
    output valid_output
);
    wire [WIDTH-1:0] priority_mask;
    wire [WIDTH-1:0] one_hot;
    wire [$clog2(WIDTH)-1:0] selected_index;
    
    priority_mask_gen #(WIDTH) mask_gen(
        .data_vector(data_vector),
        .priority_mask(priority_mask)
    );
    
    one_hot_gen #(WIDTH) hot_gen(
        .data_vector(data_vector),
        .priority_mask(priority_mask),
        .one_hot(one_hot)
    );
    
    index_selector #(WIDTH) idx_sel(
        .one_hot(one_hot),
        .selected_index(selected_index)
    );
    
    brent_kung_adder #($clog2(WIDTH)) index_adder(
        .a(selected_index),
        .b(0),
        .sum(encoded_output)
    );
    
    assign valid_output = |data_vector;
endmodule