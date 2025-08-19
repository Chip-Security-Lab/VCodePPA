//SystemVerilog
module variable_step_shifter (
    input [15:0] din,
    input [1:0] step_mode,  // 00:+1, 01:+2, 10:+4
    output [15:0] dout
);
    // 桶形移位器实现
    wire [15:0] stage0_out;
    wire [15:0] stage1_out;
    wire [15:0] stage2_out;
    
    // 第一级移位（+1或不移位）
    assign stage0_out = step_mode[0] ? {din[14:0], din[15]} : din;
    
    // 第二级移位（+2或不移位）
    assign stage1_out = step_mode[1] ? {stage0_out[13:0], stage0_out[15:14]} : stage0_out;
    
    // 根据是否同时为10（+4）情况，额外处理
    assign stage2_out = (step_mode == 2'b10) ? {stage1_out[11:0], stage1_out[15:12]} : stage1_out;
    
    // 输出结果
    assign dout = stage2_out;
endmodule