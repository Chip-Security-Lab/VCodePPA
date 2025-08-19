//SystemVerilog
module RangeDetector_WindowFSM #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] win_low,
    input [WIDTH-1:0] win_high,
    output reg cross_event
);
// 使用localparam替代SystemVerilog的typedef enum
localparam INSIDE = 1'b0;
localparam OUTSIDE = 1'b1;

reg current_state, next_state;
wire is_below_low, is_above_high;
wire [WIDTH:0] prefix_sub_low, prefix_sub_high;
wire [WIDTH-1:0] g_low[WIDTH-1:0];
wire [WIDTH-1:0] p_low[WIDTH-1:0];
wire [WIDTH-1:0] g_high[WIDTH-1:0];
wire [WIDTH-1:0] p_high[WIDTH-1:0];

// 并行前缀减法器实现 - 初始化传播和生成信号
genvar i;
generate
    for (i = 0; i < WIDTH; i = i + 1) begin: gen_prefix_init
        // 低边界检查的前缀信号
        assign g_low[i] = ~data_in[i] & win_low[i];
        assign p_low[i] = ~(data_in[i] ^ win_low[i]);
        
        // 高边界检查的前缀信号
        assign g_high[i] = ~win_high[i] & data_in[i];
        assign p_high[i] = ~(data_in[i] ^ win_high[i]);
    end
endgenerate

// 并行前缀减法器 - 计算借位
// 第一级: 2位并行前缀
wire [WIDTH-1:0] g1_low, p1_low, g1_high, p1_high;
generate
    for (i = 0; i < WIDTH; i = i + 2) begin: gen_prefix_level1
        if (i+1 < WIDTH) begin
            assign g1_low[i] = g_low[i] | (p_low[i] & g_low[i+1]);
            assign p1_low[i] = p_low[i] & p_low[i+1];
            assign g1_high[i] = g_high[i] | (p_high[i] & g_high[i+1]);
            assign p1_high[i] = p_high[i] & p_high[i+1];
            
            assign g1_low[i+1] = g_low[i+1];
            assign p1_low[i+1] = p_low[i+1];
            assign g1_high[i+1] = g_high[i+1];
            assign p1_high[i+1] = p_high[i+1];
        end else begin
            assign g1_low[i] = g_low[i];
            assign p1_low[i] = p_low[i];
            assign g1_high[i] = g_high[i];
            assign p1_high[i] = p_high[i];
        end
    end
endgenerate

// 第二级: 4位并行前缀
wire [WIDTH-1:0] g2_low, p2_low, g2_high, p2_high;
generate
    for (i = 0; i < WIDTH; i = i + 4) begin: gen_prefix_level2
        genvar j;
        for (j = 0; j < 4 && i+j < WIDTH; j = j + 1) begin: inner_level2
            if (j < 2) begin
                assign g2_low[i+j] = g1_low[i+j];
                assign p2_low[i+j] = p1_low[i+j];
                assign g2_high[i+j] = g1_high[i+j];
                assign p2_high[i+j] = p1_high[i+j];
            end else begin
                assign g2_low[i+j] = g1_low[i+j] | (p1_low[i+j] & g1_low[i]);
                assign p2_low[i+j] = p1_low[i+j] & p1_low[i];
                assign g2_high[i+j] = g1_high[i+j] | (p1_high[i+j] & g1_high[i]);
                assign p2_high[i+j] = p1_high[i+j] & p1_high[i];
            end
        end
    end
endgenerate

// 第三级: 8位并行前缀 (适合8位减法器)
wire [WIDTH-1:0] g3_low, p3_low, g3_high, p3_high;
generate
    for (i = 0; i < WIDTH; i = i + 8) begin: gen_prefix_level3
        genvar j;
        for (j = 0; j < 8 && i+j < WIDTH; j = j + 1) begin: inner_level3
            if (j < 4) begin
                assign g3_low[i+j] = g2_low[i+j];
                assign p3_low[i+j] = p2_low[i+j];
                assign g3_high[i+j] = g2_high[i+j];
                assign p3_high[i+j] = p2_high[i+j];
            end else begin
                assign g3_low[i+j] = g2_low[i+j] | (p2_low[i+j] & g2_low[i]);
                assign p3_low[i+j] = p2_low[i+j] & p2_low[i];
                assign g3_high[i+j] = g2_high[i+j] | (p2_high[i+j] & g2_high[i]);
                assign p3_high[i+j] = p2_high[i+j] & p2_high[i];
            end
        end
    end
endgenerate

// 计算最终结果
assign prefix_sub_low[0] = 1'b0; // 初始借位为0
assign prefix_sub_high[0] = 1'b0;

generate
    for (i = 0; i < WIDTH; i = i + 1) begin: gen_final_result
        assign prefix_sub_low[i+1] = g3_low[i];
        assign prefix_sub_high[i+1] = g3_high[i];
    end
endgenerate

// 确定数据是否小于下限或大于上限
assign is_below_low = prefix_sub_low[WIDTH];
assign is_above_high = prefix_sub_high[WIDTH];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        current_state <= INSIDE;
    else 
        current_state <= next_state;
end

always @(*) begin
    case(current_state)
        INSIDE:  next_state = (is_below_low || is_above_high) ? OUTSIDE : INSIDE;
        OUTSIDE: next_state = (!is_below_low && !is_above_high) ? INSIDE : OUTSIDE;
        default: next_state = INSIDE;
    endcase
end

always @(posedge clk) begin
    cross_event <= (current_state != next_state);
end
endmodule