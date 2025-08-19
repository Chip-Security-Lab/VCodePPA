//SystemVerilog
module circ_right_shift #(parameter BITS = 4) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire data_valid_in,
    output wire data_valid_out,
    output wire [BITS-1:0] q
);
    // 定义流水线阶段数 - 将BITS分成多个阶段以提高吞吐量
    localparam STAGES = (BITS > 8) ? 4 : 2;
    localparam BITS_PER_STAGE = (BITS + STAGES - 1) / STAGES;
    
    // 流水线寄存器
    reg [BITS-1:0] shifter_stage1;
    reg [BITS-1:0] shifter_stage2;
    reg [STAGES-1:0] valid_pipeline;
    
    // 生成部分移位结果
    wire [BITS-1:0] partial_shift_stage1;
    
    // 第一级流水线 - 初始化或部分移位
    assign partial_shift_stage1 = en ? {shifter_stage1[0], shifter_stage1[BITS-1:1]} : shifter_stage1;
    
    // 流水线控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifter_stage1 <= {{BITS-1{1'b0}}, 1'b1};  // Initialize with one hot
            shifter_stage2 <= {{BITS-1{1'b0}}, 1'b1};
            valid_pipeline <= {STAGES{1'b0}};
        end
        else begin
            // 第一级流水线
            shifter_stage1 <= partial_shift_stage1;
            
            // 第二级流水线 - 最终结果
            shifter_stage2 <= shifter_stage1;
            
            // 有效信号流水线
            valid_pipeline <= {valid_pipeline[STAGES-2:0], data_valid_in};
        end
    end
    
    // 输出赋值
    assign q = shifter_stage2;
    assign data_valid_out = valid_pipeline[STAGES-1];
endmodule