//SystemVerilog
module en_rst_shifter (
    input wire clk,
    input wire rst,
    input wire en,
    input wire [1:0] mode,   // 00: hold, 01: shift left, 10: shift right
    input wire serial_in,
    output wire [3:0] data
);
    // 流水线阶段寄存器
    reg [3:0] data_stage1;
    reg [3:0] data_stage2;
    
    // data_stage2的缓冲寄存器，分别用于不同分支
    reg [3:0] data_stage2_buf1;
    reg [3:0] data_stage2_buf2;
    
    // 控制信号流水线寄存器
    reg valid_stage1;
    reg valid_stage2;
    
    // 输入捕获寄存器
    reg [1:0] mode_stage1;
    reg serial_in_stage1;
    
    // 第一级流水线 - 输入捕获
    always @(posedge clk) begin
        if (rst) begin
            mode_stage1 <= 2'b00;
            serial_in_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            mode_stage1 <= mode;
            serial_in_stage1 <= serial_in;
            valid_stage1 <= en;
        end
    end

    // data_stage2缓冲寄存器更新
    always @(posedge clk) begin
        if (rst) begin
            data_stage2_buf1 <= 4'b0000;
            data_stage2_buf2 <= 4'b0000;
        end
        else begin
            data_stage2_buf1 <= data_stage2;
            data_stage2_buf2 <= data_stage2;
        end
    end

    // 第二级流水线 - 操作计算
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            case(mode_stage1)
                2'b01: data_stage1 <= {data_stage2_buf1[2:0], serial_in_stage1};  // Left
                2'b10: data_stage1 <= {serial_in_stage1, data_stage2_buf1[3:1]};  // Right
                default: data_stage1 <= data_stage2_buf2;                         // Hold
            endcase
            valid_stage2 <= 1'b1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end

    // 第三级流水线 - 输出寄存
    always @(posedge clk) begin
        if (rst) begin
            data_stage2 <= 4'b0000;
        end
        else if (valid_stage2) begin
            data_stage2 <= data_stage1;
        end
    end

    // 输出连接
    assign data = data_stage2;
endmodule