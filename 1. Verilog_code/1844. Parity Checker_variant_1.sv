//SystemVerilog
module parity_checker #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] data_in,
    input  wire             parity_in,
    input  wire             odd_parity_mode,
    output wire             error_flag
);

    // 使用并行前缀树结构计算奇偶校验
    wire [WIDTH-1:0] parity_tree [0:$clog2(WIDTH)];
    wire [WIDTH-1:0] parity_mask;
    
    // 初始化第一层
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : init_layer
            assign parity_tree[0][i] = data_in[i];
        end
    endgenerate

    // 构建并行前缀树
    genvar level;
    generate
        for (level = 1; level <= $clog2(WIDTH); level = level + 1) begin : tree_level
            for (i = 0; i < WIDTH; i = i + 1) begin : tree_node
                if (i < (1 << (level-1))) begin
                    assign parity_tree[level][i] = parity_tree[level-1][i];
                end else begin
                    assign parity_tree[level][i] = parity_tree[level-1][i] ^ 
                                                 parity_tree[level-1][i - (1 << (level-1))];
                end
            end
        end
    endgenerate

    // 最终奇偶校验结果
    wire final_parity = parity_tree[$clog2(WIDTH)][WIDTH-1];
    
    // 错误标志计算
    assign error_flag = final_parity ^ odd_parity_mode ^ parity_in;

endmodule