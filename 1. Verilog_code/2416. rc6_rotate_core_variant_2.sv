//SystemVerilog
module rc6_rotate_core (
    input clk, en,
    input [31:0] a_in, b_in,
    output reg [31:0] data_out
);
    wire [4:0] rot_offset = b_in[4:0];
    reg [31:0] rotated_val;
    reg [31:0] barrel_shift_result_reg;
    
    // 桶形移位器实现
    wire [31:0] stage0_left, stage0_right;
    wire [31:0] stage1_left, stage1_right;
    wire [31:0] stage2_left, stage2_right;
    reg [31:0] stage2_left_reg, stage2_right_reg;
    wire [31:0] stage3_left, stage3_right;
    wire [31:0] stage4_left, stage4_right;
    wire [31:0] barrel_shift_result;
    reg [4:0] rot_offset_reg;
    
    // 第一级：阶段0和阶段1的组合逻辑
    assign stage0_left = rot_offset[0] ? {a_in[30:0], a_in[31]} : a_in;
    assign stage1_left = rot_offset[1] ? {stage0_left[29:0], stage0_left[31:30]} : stage0_left;
    
    assign stage0_right = rot_offset[0] ? {a_in[0], a_in[31:1]} : a_in;
    assign stage1_right = rot_offset[1] ? {stage0_right[1:0], stage0_right[31:2]} : stage0_right;

    // 插入流水线寄存器，将桶形移位器分成两部分
    always @(posedge clk) begin
        if (en) begin
            stage2_left_reg <= rot_offset[2] ? {stage1_left[27:0], stage1_left[31:28]} : stage1_left;
            stage2_right_reg <= rot_offset[2] ? {stage1_right[3:0], stage1_right[31:4]} : stage1_right;
            rot_offset_reg <= rot_offset;
        end
    end
    
    // 第二级：阶段3和阶段4的组合逻辑
    assign stage3_left = rot_offset_reg[3] ? {stage2_left_reg[23:0], stage2_left_reg[31:24]} : stage2_left_reg;
    assign stage4_left = rot_offset_reg[4] ? {stage3_left[15:0], stage3_left[31:16]} : stage3_left;
    
    assign stage3_right = rot_offset_reg[3] ? {stage2_right_reg[7:0], stage2_right_reg[31:8]} : stage2_right_reg;
    assign stage4_right = rot_offset_reg[4] ? {stage3_right[15:0], stage3_right[31:16]} : stage3_right;
    
    // 组合右移和左移结果
    assign barrel_shift_result = (stage4_left & {32{rot_offset_reg != 5'b0}}) | 
                               (stage4_right & {32{rot_offset_reg == 5'b0}});
    
    // 流水线处理最终结果
    always @(posedge clk) begin
        if (en) begin
            barrel_shift_result_reg <= barrel_shift_result;
            rotated_val <= barrel_shift_result_reg;
            data_out <= rotated_val + 32'h9E3779B9; // Golden ratio
        end
    end
endmodule