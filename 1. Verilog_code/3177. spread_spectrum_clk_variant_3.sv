//SystemVerilog
module spread_spectrum_clk(
    input clk_in,
    input rst,
    input [3:0] modulation,
    output reg clk_out
);
    // 流水线阶段1信号
    reg [5:0] counter_stage1;
    reg [3:0] mod_counter_stage1;
    reg [3:0] divisor_stage1;
    reg [3:0] modulation_stage1;
    reg clk_out_stage1;
    
    // 流水线阶段2信号
    reg [5:0] counter_stage2;
    reg [3:0] divisor_stage2;
    reg clk_out_stage2;
    reg [3:0] mod_counter_stage2;
    reg mod_flag_stage2;
    
    // 流水线阶段3信号
    reg [5:0] counter_stage3;
    reg [3:0] divisor_stage3;
    reg clk_out_stage3;
    reg counter_reset_stage3;
    
    // Brent-Kung加法器相关信号
    wire [5:0] bk_sum;
    wire [5:0] counter_plus_one;
    
    // 预计算信号
    wire [5:0] counter_next;
    wire [3:0] divisor_next;
    wire clk_out_next;
    wire counter_reset_next;
    
    // Brent-Kung加法器实例化
    brent_kung_adder bk_adder_inst (
        .a(counter_stage2),
        .b(6'd1),
        .sum(counter_plus_one)
    );
    
    // 组合逻辑预计算
    assign counter_next = counter_reset_stage3 ? 6'd0 : counter_plus_one;
    assign divisor_next = mod_flag_stage2 ? (4'd8 + (modulation_stage1 & {3'b000, counter_stage1[5]})) : divisor_stage1;
    assign clk_out_next = (counter_stage2 >= {2'b00, divisor_stage2}) ? ~clk_out_stage2 : clk_out_stage2;
    assign counter_reset_next = (counter_stage2 >= {2'b00, divisor_stage2});
    
    // 流水线阶段1
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            mod_counter_stage1 <= 4'd0;
            modulation_stage1 <= 4'd0;
            counter_stage1 <= 6'd0;
            divisor_stage1 <= 4'd8;
            clk_out_stage1 <= 1'b0;
        end else begin
            mod_counter_stage1 <= mod_counter_stage1 + 4'd1;
            modulation_stage1 <= modulation;
            counter_stage1 <= counter_next;
            divisor_stage1 <= divisor_next;
            clk_out_stage1 <= clk_out_next;
        end
    end
    
    // 流水线阶段2
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            mod_counter_stage2 <= 4'd0;
            divisor_stage2 <= 4'd8;
            counter_stage2 <= 6'd0;
            clk_out_stage2 <= 1'b0;
            mod_flag_stage2 <= 1'b0;
        end else begin
            mod_counter_stage2 <= mod_counter_stage1;
            counter_stage2 <= counter_stage1;
            clk_out_stage2 <= clk_out_stage1;
            mod_flag_stage2 <= (mod_counter_stage1 == 4'd15);
            divisor_stage2 <= divisor_next;
        end
    end
    
    // 流水线阶段3
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_stage3 <= 6'd0;
            divisor_stage3 <= 4'd8;
            clk_out_stage3 <= 1'b0;
            counter_reset_stage3 <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            divisor_stage3 <= divisor_stage2;
            counter_stage3 <= counter_next;
            clk_out_stage3 <= clk_out_next;
            counter_reset_stage3 <= counter_reset_next;
            clk_out <= clk_out_next;
        end
    end
endmodule

module brent_kung_adder(
    input [5:0] a,
    input [5:0] b,
    output [5:0] sum
);
    wire [5:0] g, p;
    wire [5:0] g_level1, p_level1;
    wire [5:0] g_level2, p_level2;
    wire [5:0] carry;
    
    assign g = a & b;
    assign p = a ^ b;
    
    // 预计算第一级
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    assign g_level1[1] = g[1] | (p[1] & g[0]);
    assign p_level1[1] = p[1] & p[0];
    assign g_level1[2] = g[2];
    assign p_level1[2] = p[2];
    assign g_level1[3] = g[3] | (p[3] & g[2]);
    assign p_level1[3] = p[3] & p[2];
    assign g_level1[4] = g[4];
    assign p_level1[4] = p[4];
    assign g_level1[5] = g[5] | (p[5] & g[4]);
    assign p_level1[5] = p[5] & p[4];
    
    // 预计算第二级
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    assign g_level2[2] = g_level1[2];
    assign p_level2[2] = p_level1[2];
    assign g_level2[3] = g_level1[3] | (p_level1[3] & g_level1[1]);
    assign p_level2[3] = p_level1[3] & p_level1[1];
    assign g_level2[4] = g_level1[4];
    assign p_level2[4] = p_level1[4];
    assign g_level2[5] = g_level1[5] | (p_level1[5] & g_level1[3]);
    assign p_level2[5] = p_level1[5] & p_level1[3];
    
    // 预计算进位
    assign carry[0] = 1'b0;
    assign carry[1] = g_level2[0];
    assign carry[2] = g_level2[1];
    assign carry[3] = g_level2[2] | (p_level2[2] & g_level2[0]);
    assign carry[4] = g_level2[3];
    assign carry[5] = g_level2[4] | (p_level2[4] & g_level2[3]);
    
    assign sum = p ^ carry;
endmodule