//SystemVerilog
module async_right_shifter (
    input wire clk,
    input wire rst_n,
    input wire data_in,
    input wire [3:0] control,
    output wire data_out
);
    // 分级处理移位操作，打破长链路径
    reg [4:0] shift_stage_reg;
    reg [3:0] control_reg;
    
    // 寄存输入信号和控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_stage_reg[4] <= 1'b0;
            control_reg <= 4'b0;
        end else begin
            shift_stage_reg[4] <= data_in;
            control_reg <= control; // 寄存控制信号减少扇出负载
        end
    end
    
    // 将长级联路径拆分为两个独立处理的部分
    wire stage4_to_3 = control_reg[3] ? shift_stage_reg[4] : shift_stage_reg[3];
    wire stage3_to_2 = control_reg[2] ? stage4_to_3 : shift_stage_reg[2];
    
    wire stage2_to_1 = control_reg[1] ? shift_stage_reg[2] : shift_stage_reg[1];
    wire stage1_to_0 = control_reg[0] ? shift_stage_reg[1] : shift_stage_reg[0];
    
    // 分段流水线寄存器，分割高低两部分
    reg mid_stage_3_2;
    reg mid_stage_1_0;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mid_stage_3_2 <= 1'b0;
            mid_stage_1_0 <= 1'b0;
        end else begin
            mid_stage_3_2 <= stage3_to_2;
            mid_stage_1_0 <= stage1_to_0;
        end
    end
    
    // 第二阶段流水线 - 更新寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_stage_reg[3:0] <= 4'b0;
        end else begin
            shift_stage_reg[3] <= stage4_to_3;
            shift_stage_reg[2] <= mid_stage_3_2;
            shift_stage_reg[1] <= stage2_to_1;
            shift_stage_reg[0] <= mid_stage_1_0;
        end
    end
    
    // 输出逻辑
    assign data_out = shift_stage_reg[0];
    
endmodule