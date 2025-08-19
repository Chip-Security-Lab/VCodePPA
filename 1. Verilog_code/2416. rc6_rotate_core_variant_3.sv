//SystemVerilog
module rc6_rotate_core (
    input wire clk,
    input wire en,
    input wire [31:0] a_in, b_in,
    output reg [31:0] data_out
);
    // 组合逻辑部分 - 桶形移位器
    wire [4:0] rot_offset;
    wire [31:0] barrel_shifted_result;
    wire [31:0] next_data_out;
    reg [31:0] rotated_val;

    // 组合逻辑模块实例化
    barrel_shifter barrel_shift_inst (
        .data_in(a_in),
        .rot_offset(rot_offset),
        .shifted_result(barrel_shifted_result)
    );

    // 组合逻辑信号连接
    assign rot_offset = b_in[4:0];
    assign next_data_out = rotated_val + 32'h9E3779B9; // Golden ratio

    // 时序逻辑部分
    always @(posedge clk) begin
        if (en) begin
            rotated_val <= barrel_shifted_result;
            data_out <= next_data_out;
        end
    end
endmodule

// 纯组合逻辑模块 - 桶形移位器
module barrel_shifter (
    input wire [31:0] data_in,
    input wire [4:0] rot_offset,
    output wire [31:0] shifted_result
);
    // 内部导线声明
    wire [31:0] stage0, stage1, stage2, stage3;
    
    // 5级桶形移位实现
    // 第1级移位 - 移动0或1位
    assign stage0 = rot_offset[0] ? {data_in[30:0], data_in[31]} : data_in;
    
    // 第2级移位 - 移动0或2位
    assign stage1 = rot_offset[1] ? {stage0[29:0], stage0[31:30]} : stage0;
    
    // 第3级移位 - 移动0或4位
    assign stage2 = rot_offset[2] ? {stage1[27:0], stage1[31:28]} : stage1;
    
    // 第4级移位 - 移动0或8位
    assign stage3 = rot_offset[3] ? {stage2[23:0], stage2[31:24]} : stage2;
    
    // 第5级移位 - 移动0或16位
    assign shifted_result = rot_offset[4] ? {stage3[15:0], stage3[31:16]} : stage3;
endmodule