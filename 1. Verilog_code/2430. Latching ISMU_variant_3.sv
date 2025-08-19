//SystemVerilog
module latch_ismu #(parameter WIDTH = 16)(
    input wire i_clk, i_rst_b,
    input wire [WIDTH-1:0] i_int_src,
    input wire i_latch_en,
    input wire [WIDTH-1:0] i_int_clr,
    output reg [WIDTH-1:0] o_latched_int,
    // 流水线控制信号
    input wire i_valid_in,
    output reg o_valid_out,
    input wire i_ready_in,
    output wire o_ready_out
);
    // 流水线阶段1寄存器
    reg [WIDTH-1:0] int_src_stage1;
    reg latch_en_stage1;
    reg [WIDTH-1:0] int_clr_stage1;
    reg [WIDTH-1:0] latched_int_stage1;
    reg valid_stage1;
    
    // 流水线阶段2寄存器
    reg [WIDTH-1:0] int_set_stage2;
    reg [WIDTH-1:0] int_clr_stage2;
    reg [WIDTH-1:0] latched_int_stage2;
    reg valid_stage2;
    
    // 流水线阶段3寄存器（新增中间寄存器以切割关键路径）
    reg [WIDTH-1:0] int_or_result_stage3;
    reg [WIDTH-1:0] int_clr_stage3;
    reg valid_stage3;
    
    // 流水线控制逻辑
    wire stall = o_valid_out && !i_ready_in;
    assign o_ready_out = !stall;
    
    // 阶段1: 输入寄存并计算INT_SET
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b) begin
            int_src_stage1 <= {WIDTH{1'b0}};
            latch_en_stage1 <= 1'b0;
            int_clr_stage1 <= {WIDTH{1'b0}};
            latched_int_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (!stall) begin
            int_src_stage1 <= i_int_src;
            latch_en_stage1 <= i_latch_en;
            int_clr_stage1 <= i_int_clr;
            latched_int_stage1 <= o_latched_int;
            valid_stage1 <= i_valid_in;
        end
    end
    
    // 阶段2: 计算INT_SET
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b) begin
            int_set_stage2 <= {WIDTH{1'b0}};
            int_clr_stage2 <= {WIDTH{1'b0}};
            latched_int_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (!stall) begin
            // 切割关键路径，分离掩码计算和按位与操作
            int_set_stage2 <= int_src_stage1 & {WIDTH{latch_en_stage1}};
            int_clr_stage2 <= int_clr_stage1;
            latched_int_stage2 <= latched_int_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3: 计算中间OR结果（新增阶段以切割关键路径）
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b) begin
            int_or_result_stage3 <= {WIDTH{1'b0}};
            int_clr_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else if (!stall) begin
            // 将OR操作与后续的与非操作分离
            int_or_result_stage3 <= latched_int_stage2 | int_set_stage2;
            int_clr_stage3 <= int_clr_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出阶段: 最终中断状态计算与输出
    always @(posedge i_clk or negedge i_rst_b) begin
        if (!i_rst_b) begin
            o_latched_int <= {WIDTH{1'b0}};
            o_valid_out <= 1'b0;
        end else if (!stall) begin
            // 最终的与非操作
            o_latched_int <= int_or_result_stage3 & ~int_clr_stage3;
            o_valid_out <= valid_stage3;
        end
    end
endmodule