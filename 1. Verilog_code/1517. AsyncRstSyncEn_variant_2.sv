//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog standard
module AsyncRstSyncEn #(parameter W=6) (
    input wire sys_clk,
    input wire async_rst_n,
    input wire en_shift,
    input wire serial_data,
    output wire [W-1:0] shift_reg
);
    // 定义流水线寄存器与控制信号
    reg [W-1:0] shift_reg_stage1;
    reg [W-1:0] shift_reg_stage2;
    reg [W-1:0] shift_reg_stage3;
    
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    reg serial_data_stage1;
    reg serial_data_stage2;
    
    // 时钟树缓冲 - 分散高扇出时钟信号负载
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // 异步复位信号缓冲 - 分散高扇出复位信号负载
    wire rst_n_buf1, rst_n_buf2, rst_n_buf3;
    
    // 时钟缓冲器实例化
    assign clk_buf1 = sys_clk;
    assign clk_buf2 = sys_clk;
    assign clk_buf3 = sys_clk;
    
    // 复位缓冲器实例化
    assign rst_n_buf1 = async_rst_n;
    assign rst_n_buf2 = async_rst_n;
    assign rst_n_buf3 = async_rst_n;
    
    // 流水线第一级 - 捕获输入与控制信号
    always @(posedge clk_buf1 or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            serial_data_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            shift_reg_stage1 <= {W{1'b0}};
        end else if (en_shift) begin
            valid_stage1 <= 1'b1;
            serial_data_stage1 <= serial_data;
            shift_reg_stage1 <= shift_reg_stage3; // 反馈上一次结果用于下次移位
        end else begin
            valid_stage1 <= 1'b0;
            serial_data_stage1 <= serial_data;
            shift_reg_stage1 <= shift_reg_stage1;
        end
    end
    
    // 流水线第二级 - 处理移位操作的第一部分
    always @(posedge clk_buf2 or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            valid_stage2 <= 1'b0;
            serial_data_stage2 <= 1'b0;
            shift_reg_stage2 <= {W{1'b0}};
        end else if (valid_stage1) begin
            valid_stage2 <= 1'b1;
            serial_data_stage2 <= serial_data_stage1;
            shift_reg_stage2 <= {shift_reg_stage1[W-2:0], serial_data_stage1};
        end else begin
            valid_stage2 <= 1'b0;
            serial_data_stage2 <= serial_data_stage1;
            shift_reg_stage2 <= shift_reg_stage1;
        end
    end
    
    // 流水线第三级 - 处理移位操作的第二部分和输出
    always @(posedge clk_buf3 or negedge rst_n_buf3) begin
        if (!rst_n_buf3) begin
            valid_stage3 <= 1'b0;
            shift_reg_stage3 <= {W{1'b0}};
        end else begin
            valid_stage3 <= valid_stage2;
            shift_reg_stage3 <= shift_reg_stage2;
        end
    end
    
    // 输出映射
    assign shift_reg = shift_reg_stage3;
    
endmodule