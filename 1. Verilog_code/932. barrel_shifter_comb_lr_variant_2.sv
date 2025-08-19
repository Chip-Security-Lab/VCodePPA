//SystemVerilog
module barrel_shifter_comb_lr (
    input wire clk,        // 时钟信号
    input wire rst_n,      // 复位信号
    input wire [15:0] din, // 输入数据
    input wire [3:0] shift,// 移位量
    input wire valid_in,   // 输入有效信号
    output reg [15:0] dout,// 输出数据
    output reg valid_out   // 输出有效信号
);

    // 流水线寄存器
    reg [15:0] stage1_data, stage2_data;
    reg [3:0] stage1_shift, stage2_shift;
    reg stage1_valid, stage2_valid;
    
    // 中间数据路径信号
    wire [15:0] shift_stage1, shift_stage2;
    
    // 第一级移位 - 处理低2位移位
    assign shift_stage1 = (stage1_shift[1:0] == 2'b00) ? stage1_data :
                          (stage1_shift[1:0] == 2'b01) ? {1'b0, stage1_data[15:1]} :
                          (stage1_shift[1:0] == 2'b10) ? {2'b0, stage1_data[15:2]} :
                                                         {3'b0, stage1_data[15:3]};
    
    // 第二级移位 - 处理高2位移位
    assign shift_stage2 = (stage2_shift[3:2] == 2'b00) ? stage2_data :
                          (stage2_shift[3:2] == 2'b01) ? {4'b0, stage2_data[15:4]} :
                          (stage2_shift[3:2] == 2'b10) ? {8'b0, stage2_data[15:8]} :
                                                         {12'b0, stage2_data[15:12]};
    
    // 流水线寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有寄存器
            stage1_data <= 16'b0;
            stage1_shift <= 4'b0;
            stage1_valid <= 1'b0;
            
            stage2_data <= 16'b0;
            stage2_shift <= 4'b0;
            stage2_valid <= 1'b0;
            
            dout <= 16'b0;
            valid_out <= 1'b0;
        end else begin
            // 第一级流水线
            stage1_data <= din;
            stage1_shift <= shift;
            stage1_valid <= valid_in;
            
            // 第二级流水线
            stage2_data <= shift_stage1;
            stage2_shift <= stage1_shift;
            stage2_valid <= stage1_valid;
            
            // 输出级
            dout <= shift_stage2;
            valid_out <= stage2_valid;
        end
    end

endmodule