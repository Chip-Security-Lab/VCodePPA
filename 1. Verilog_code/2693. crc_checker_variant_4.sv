//SystemVerilog
module crc_checker(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire [7:0] crc_in,
    input wire data_valid,
    output reg crc_valid,
    output reg [7:0] calculated_crc
);
    parameter [7:0] POLY = 8'hD5;

    // 流水线寄存器和控制信号
    reg [7:0] data_stage1, data_stage2;
    reg [7:0] crc_stage1, crc_stage2;
    reg [7:0] crc_calc_stage1, crc_calc_stage2;
    reg valid_stage1, valid_stage2;
    
    // 数据寄存输入 - 第一流水线级
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= 8'h00;
            crc_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            crc_stage1 <= crc_in;
            valid_stage1 <= data_valid;
        end
    end
    
    // CRC计算 - 第一流水线级
    always @(posedge clk) begin
        if (rst) begin
            crc_calc_stage1 <= 8'h00;
        end else if (data_valid) begin
            crc_calc_stage1 <= {calculated_crc[6:0], 1'b0} ^ 
                              ((calculated_crc[7] ^ data_in[0]) ? POLY : 8'h00);
        end else begin
            crc_calc_stage1 <= calculated_crc;
        end
    end
    
    // 数据寄存 - 第二流水线级
    always @(posedge clk) begin
        if (rst) begin
            data_stage2 <= 8'h00;
            crc_stage2 <= 8'h00;
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            crc_stage2 <= crc_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // CRC计算数据 - 第二流水线级
    always @(posedge clk) begin
        if (rst) begin
            crc_calc_stage2 <= 8'h00;
        end else begin
            crc_calc_stage2 <= crc_calc_stage1;
        end
    end
    
    // CRC计算结果输出 - 第三流水线级
    always @(posedge clk) begin
        if (rst) begin
            calculated_crc <= 8'h00;
        end else begin
            calculated_crc <= crc_calc_stage2;
        end
    end
    
    // CRC有效性判断 - 第三流水线级
    always @(posedge clk) begin
        if (rst) begin
            crc_valid <= 1'b0;
        end else if (valid_stage2) begin
            crc_valid <= (crc_calc_stage2 == crc_stage2);
        end else begin
            crc_valid <= 1'b0;
        end
    end
endmodule