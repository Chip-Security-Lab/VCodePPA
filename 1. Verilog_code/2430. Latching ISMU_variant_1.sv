//SystemVerilog
module latch_ismu #(parameter WIDTH = 16)(
    input wire i_clk, i_rst_b,
    input wire [WIDTH-1:0] i_int_src,
    input wire i_latch_en,
    input wire [WIDTH-1:0] i_int_clr,
    input wire i_valid_in,
    output wire o_ready_in,
    output reg o_valid_out,
    input wire i_ready_out,
    output reg [WIDTH-1:0] o_latched_int
);
    // 流水线级别 1 - 输入寄存器和控制信号
    reg [WIDTH-1:0] i_int_src_stage1;
    reg i_latch_en_stage1;
    reg [WIDTH-1:0] i_int_clr_stage1;
    reg valid_stage1;
    
    // 流水线级别 2 - 中间计算结果
    reg [WIDTH-1:0] int_set_stage2;
    reg [WIDTH-1:0] i_int_clr_stage2;
    reg [WIDTH-1:0] o_latched_int_stage2;
    reg valid_stage2;
    
    // 流水线控制逻辑 - 优化后的路径平衡逻辑
    wire stage1_ready_pre, stage2_ready_pre;
    wire stage1_ready, stage2_ready;
    
    // 将长组合逻辑路径拆分为更平衡的结构
    assign stage2_ready_pre = ~valid_stage2;
    assign stage2_ready = stage2_ready_pre | i_ready_out;
    
    assign stage1_ready_pre = ~valid_stage1;
    assign stage1_ready = stage1_ready_pre | stage2_ready;
    
    assign o_ready_in = stage1_ready;
    
    // 预计算流水线级别1的掩码信号
    reg [WIDTH-1:0] latch_mask;
    
    // 流水线级别 1 逻辑
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b) begin
            i_int_src_stage1 <= {WIDTH{1'b0}};
            i_latch_en_stage1 <= 1'b0;
            i_int_clr_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            latch_mask <= {WIDTH{1'b0}};
        end
        else if (stage1_ready) begin
            i_int_src_stage1 <= i_int_src;
            i_latch_en_stage1 <= i_latch_en;
            i_int_clr_stage1 <= i_int_clr;
            valid_stage1 <= i_valid_in;
            latch_mask <= {WIDTH{i_latch_en}}; // 预计算掩码，减少第二级的组合逻辑延迟
        end
    end
    
    // 流水线级别 2 逻辑
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b) begin
            int_set_stage2 <= {WIDTH{1'b0}};
            i_int_clr_stage2 <= {WIDTH{1'b0}};
            o_latched_int_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else if (stage2_ready) begin
            int_set_stage2 <= i_int_src_stage1 & latch_mask; // 使用预计算的掩码
            i_int_clr_stage2 <= i_int_clr_stage1;
            o_latched_int_stage2 <= o_latched_int;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 优化输出级逻辑 - 拆分复杂表达式
    reg [WIDTH-1:0] latched_with_set;
    
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b) begin
            latched_with_set <= {WIDTH{1'b0}};
            o_latched_int <= {WIDTH{1'b0}};
            o_valid_out <= 1'b0;
        end
        else if (i_ready_out) begin
            // 将复杂表达式拆分为两个步骤，减少关键路径长度
            latched_with_set <= o_latched_int_stage2 | int_set_stage2;
            o_latched_int <= latched_with_set & ~i_int_clr_stage2;
            o_valid_out <= valid_stage2;
        end
    end
endmodule