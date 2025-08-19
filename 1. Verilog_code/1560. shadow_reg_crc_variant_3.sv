//SystemVerilog
module shadow_reg_crc #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    input valid_in,
    output reg valid_out,
    output reg [DW+3:0] reg_out  // [DW+3:DW]为CRC
);
    // 第一级流水线：计算CRC和寄存数据
    reg [DW-1:0] data_stage1;
    reg [3:0] crc_stage1;
    reg valid_stage1;
    
    wire [3:0] crc_calc = data_in[3:0] ^ data_in[7:4];
    
    // 第一级流水线寄存器
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= 0;
            crc_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else if (en) begin
            data_stage1 <= data_in;
            crc_stage1 <= crc_calc;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：合并CRC和数据输出
    always @(posedge clk) begin
        if (rst) begin
            reg_out <= 0;
            valid_out <= 0;
        end
        else if (en) begin
            reg_out <= {crc_stage1, data_stage1};
            valid_out <= valid_stage1;
        end
    end
endmodule