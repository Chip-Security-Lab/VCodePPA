//SystemVerilog
module ManchesterDecoder (
    input clk_16x,
    input manchester_in,
    output reg [7:0] decoded_data,
    output reg req,        // 替代了原来的valid信号
    input ack              // 新增的应答信号
);
    reg [3:0] bit_counter;
    reg [15:0] shift_reg;
    wire [3:0] next_counter;
    reg req_pending;       // 跟踪请求状态
    
    // Kogge-Stone adder implementation for 4-bit counter increment
    // Generate propagate signals
    wire [3:0] p;
    assign p = bit_counter;
    
    // Generate generate signals 
    wire [3:0] g;
    assign g = 4'b0000;
    
    // First stage of prefix computation
    wire [3:0] p_stage1, g_stage1;
    assign p_stage1[0] = p[0];
    assign g_stage1[0] = g[0];
    
    assign p_stage1[1] = p[1];
    assign g_stage1[1] = g[1] | (p[1] & g[0]);
    
    assign p_stage1[2] = p[2];
    assign g_stage1[2] = g[2] | (p[2] & g[1]);
    
    assign p_stage1[3] = p[3];
    assign g_stage1[3] = g[3] | (p[3] & g[2]);
    
    // Second stage of prefix computation
    wire [3:0] p_stage2, g_stage2;
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[0] = g_stage1[0];
    
    assign p_stage2[1] = p_stage1[1];
    assign g_stage2[1] = g_stage1[1];
    
    assign p_stage2[2] = p_stage1[2] & p_stage1[0];
    assign g_stage2[2] = g_stage1[2] | (p_stage1[2] & g_stage1[0]);
    
    assign p_stage2[3] = p_stage1[3] & p_stage1[1];
    assign g_stage2[3] = g_stage1[3] | (p_stage1[3] & g_stage1[1]);
    
    // Third stage of prefix computation
    wire [3:0] p_stage3, g_stage3;
    assign p_stage3[0] = p_stage2[0];
    assign g_stage3[0] = g_stage2[0];
    
    assign p_stage3[1] = p_stage2[1];
    assign g_stage3[1] = g_stage2[1];
    
    assign p_stage3[2] = p_stage2[2];
    assign g_stage3[2] = g_stage2[2];
    
    assign p_stage3[3] = p_stage2[3] & p_stage2[0];
    assign g_stage3[3] = g_stage2[3] | (p_stage2[3] & g_stage2[0]);
    
    // Computing sum
    wire carry_in = 1'b1; // For increment operation
    wire [3:0] carry;
    assign carry[0] = carry_in;
    assign carry[1] = g_stage3[0] | (p_stage3[0] & carry_in);
    assign carry[2] = g_stage3[1] | (p_stage3[1] & carry[1]);
    assign carry[3] = g_stage3[2] | (p_stage3[2] & carry[2]);
    
    assign next_counter = bit_counter ^ {carry[2:0], carry_in};
    
    // Reset counter logic
    wire is_counter_max;
    assign is_counter_max = (bit_counter == 4'b1111) ? 1'b1 : 1'b0;
    
    always @(posedge clk_16x) begin
        shift_reg <= {shift_reg[14:0], manchester_in};
        
        if (req_pending && ack) begin
            // 应答已收到，清除请求状态
            req <= 1'b0;
            req_pending <= 1'b0;
        end
        
        if (shift_reg[15:8] == 8'b01010101 && !req_pending) begin
            // 检测到数据模式且没有未处理的请求
            decoded_data <= shift_reg[7:0];
            req <= 1'b1;
            req_pending <= 1'b1;
            bit_counter <= 4'b0000;
        end else if (!req_pending) begin
            // 只有在没有未处理的请求时才更新计数器
            bit_counter <= is_counter_max ? 4'b0000 : next_counter;
        end
    end
endmodule