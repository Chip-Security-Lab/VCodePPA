//SystemVerilog
module pipelined_rgb_to_ycbcr (
    input clk, rst_n,
    input [23:0] rgb_in,
    input data_valid,
    output reg [23:0] ycbcr_out,
    output reg out_valid
);
    // 寄存输入信号，降低输入端到第一级寄存器的延迟
    reg [23:0] rgb_reg;
    reg data_valid_reg;
    
    // 第一阶段：寄存输入信号
    always @(posedge clk) begin
        if (!rst_n) begin
            rgb_reg <= 24'h0;
            data_valid_reg <= 1'b0;
        end else begin
            rgb_reg <= rgb_in;
            data_valid_reg <= data_valid;
        end
    end
    
    // 基于寄存的输入计算YCbCr值
    wire [15:0] y_temp, cb_temp, cr_temp;
    
    assign y_temp = ((16'd66 * rgb_reg[23:16] + 16'd129 * rgb_reg[15:8] + 
                    16'd25 * rgb_reg[7:0] + 16'd128) >> 8) + 16;
    assign cb_temp = ((16'd38 * (rgb_reg[23:16] ^ 8'hFF) + 16'd74 * (rgb_reg[15:8] ^ 8'hFF) + 
                    16'd112 * rgb_reg[7:0] + 16'd128) >> 8) + 128;
    assign cr_temp = ((16'd112 * rgb_reg[23:16] + 16'd94 * (rgb_reg[15:8] ^ 8'hFF) + 
                    16'd18 * (rgb_reg[7:0] ^ 8'hFF) + 16'd128) >> 8) + 128;
    
    // 处理限幅逻辑
    wire [7:0] y_clipped = (y_temp > 255) ? 8'd255 : y_temp[7:0];
    wire [7:0] cb_clipped = (cb_temp > 255) ? 8'd255 : cb_temp[7:0];
    wire [7:0] cr_clipped = (cr_temp > 255) ? 8'd255 : cr_temp[7:0];
    
    // 阶段1寄存器：存储限幅后的结果
    reg [7:0] y_stage1, cb_stage1, cr_stage1;
    reg valid_stage1;
    
    // 阶段2寄存器：输出准备阶段
    reg [7:0] y_stage2, cb_stage2, cr_stage2;
    reg valid_stage2;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            // 复位所有寄存器
            y_stage1 <= 8'h0;
            cb_stage1 <= 8'h0;
            cr_stage1 <= 8'h0;
            valid_stage1 <= 1'b0;
            
            y_stage2 <= 8'h0;
            cb_stage2 <= 8'h0;
            cr_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
            
            ycbcr_out <= 24'h0;
            out_valid <= 1'b0;
        end else begin
            // 阶段1：限幅后的值存入寄存器
            y_stage1 <= y_clipped;
            cb_stage1 <= cb_clipped;
            cr_stage1 <= cr_clipped;
            valid_stage1 <= data_valid_reg;
            
            // 阶段2：将阶段1的值传递到阶段2
            y_stage2 <= y_stage1;
            cb_stage2 <= cb_stage1;
            cr_stage2 <= cr_stage1;
            valid_stage2 <= valid_stage1;
            
            // 输出阶段：将阶段2的值传递到输出
            ycbcr_out <= {y_stage2, cb_stage2, cr_stage2};
            out_valid <= valid_stage2;
        end
    end
endmodule