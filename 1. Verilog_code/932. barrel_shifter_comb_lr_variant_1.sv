//SystemVerilog
module barrel_shifter_comb_lr (
    input wire clk,        // 时钟信号
    input wire rst_n,      // 复位信号
    input wire [15:0] din, // 输入数据
    input wire [3:0] shift,// 移位量
    input wire valid_in,   // 输入有效信号
    output wire [15:0] dout,// 输出数据
    output wire valid_out  // 输出有效信号
);

    // 内部流水线寄存器
    reg [15:0] shift_stage1, shift_stage2;
    reg [3:0] shift_amt_stage1, shift_amt_stage2;
    reg valid_stage1, valid_stage2;
    
    // 中间移位结果
    wire [15:0] level1_out, level2_out;
    
    // 第一级流水线 - 处理0/1位移位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_stage1 <= 16'b0;
            shift_amt_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            shift_stage1 <= din;
            shift_amt_stage1 <= shift;
            valid_stage1 <= valid_in;
        end
    end
    
    // 级联实现移位功能 - 第一级处理低位移位
    assign level1_out = shift_amt_stage1[0] ? {1'b0, shift_stage1[15:1]} : shift_stage1;
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_stage2 <= 16'b0;
            shift_amt_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
        end else begin
            shift_stage2 <= level1_out;
            shift_amt_stage2 <= shift_amt_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 级联实现移位功能 - 第二级处理高位移位
    assign level2_out = shift_amt_stage2[1] ? {2'b0, shift_stage2[15:2]} : shift_stage2;
    
    // 最终输出寄存器
    reg [15:0] dout_reg;
    reg valid_out_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_reg <= 16'b0;
            valid_out_reg <= 1'b0;
        end else begin
            // 实现最后两位移位
            if (shift_amt_stage2[2]) 
                dout_reg <= {4'b0, level2_out[15:4]};
            else 
                dout_reg <= level2_out;
                
            if (shift_amt_stage2[3]) 
                dout_reg <= {8'b0, dout_reg[15:8]};
                
            valid_out_reg <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign dout = dout_reg;
    assign valid_out = valid_out_reg;

endmodule