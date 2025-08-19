//SystemVerilog
// IEEE 1364-2005 Verilog标准
module RingShiftPipelined #(parameter RING_SIZE=5) (
    input clk,
    input rst_n,
    input rotate,
    input valid_in,
    output wire [RING_SIZE-1:0] ring_out,
    output wire valid_out
);
    // 定义流水线级数
    localparam STAGES = 3;
    
    // 流水线寄存器
    reg [RING_SIZE-1:0] ring_reg = 5'b10000;
    reg [RING_SIZE-1:0] ring_stage1;
    reg [RING_SIZE-1:0] ring_stage2;
    
    // 控制信号流水线
    reg rotate_stage1;
    reg rotate_stage2;
    
    // 有效信号流水线
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;

    // 计算中间结果的组合逻辑网络
    wire [RING_SIZE-1:0] next_ring_stage1;
    wire [RING_SIZE-1:0] next_ring_stage2;
    wire [RING_SIZE-1:0] next_ring_stage3;
    
    // 第一级流水线: 预处理输入
    assign next_ring_stage1 = ring_reg;
    
    // 第二级流水线: 执行部分移位操作
    RingShiftStage1 #(.RING_SIZE(RING_SIZE)) stage1_logic (
        .rotate(rotate_stage1),
        .current_ring(ring_stage1),
        .next_ring(next_ring_stage2)
    );
    
    // 第三级流水线: 完成移位操作
    RingShiftStage2 #(.RING_SIZE(RING_SIZE)) stage2_logic (
        .rotate(rotate_stage2),
        .current_ring(ring_stage2),
        .next_ring(next_ring_stage3)
    );
    
    // 流水线寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置所有流水线寄存器和控制信号
            ring_reg <= 5'b10000;
            ring_stage1 <= 5'b00000;
            ring_stage2 <= 5'b00000;
            rotate_stage1 <= 1'b0;
            rotate_stage2 <= 1'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end
        else begin
            // 第一级流水线
            if (valid_in) begin
                ring_stage1 <= next_ring_stage1;
                rotate_stage1 <= rotate;
                valid_stage1 <= valid_in;
            end else if (valid_stage1) begin
                valid_stage1 <= 1'b0;
            end

            // 第二级流水线
            ring_stage2 <= next_ring_stage2;
            rotate_stage2 <= rotate_stage1;
            valid_stage2 <= valid_stage1;
            
            // 第三级流水线
            ring_reg <= next_ring_stage3;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign ring_out = ring_reg;
    assign valid_out = valid_stage3;
endmodule

// 第一级移位器子模块
module RingShiftStage1 #(parameter RING_SIZE=5) (
    input rotate,
    input [RING_SIZE-1:0] current_ring,
    output [RING_SIZE-1:0] next_ring
);
    // 第一级只处理部分位的移位
    wire [RING_SIZE-1:0] temp_ring;
    assign temp_ring = rotate ? {current_ring[0], current_ring[RING_SIZE-1:1]} : current_ring;
    assign next_ring = temp_ring;
endmodule

// 第二级移位器子模块
module RingShiftStage2 #(parameter RING_SIZE=5) (
    input rotate,
    input [RING_SIZE-1:0] current_ring,
    output [RING_SIZE-1:0] next_ring
);
    // 第二级完成其余处理
    assign next_ring = current_ring;
endmodule