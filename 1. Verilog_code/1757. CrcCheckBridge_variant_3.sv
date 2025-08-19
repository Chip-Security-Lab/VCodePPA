//SystemVerilog
module CrcCheckBridge #(
    parameter DATA_W = 32,
    parameter CRC_W = 8
)(
    input clk, rst_n,
    input [DATA_W-1:0] data_in,
    input data_valid,
    output reg [DATA_W-1:0] data_out,
    output reg crc_error
);
    // 流水线寄存器
    reg [DATA_W-1:0] data_stage1, data_stage2;
    reg [CRC_W-1:0] crc_calc, crc_stage1, crc_stage2;
    reg valid_stage1, valid_stage2;
    
    // 第一级流水线：CRC计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_calc <= {CRC_W{1'b0}};
            data_stage1 <= {DATA_W{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            if (data_valid) begin
                crc_calc <= ^{data_in, crc_calc} << 1;
                data_stage1 <= data_in;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线：CRC中间阶段传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage1 <= {CRC_W{1'b0}};
            data_stage2 <= {DATA_W{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                crc_stage1 <= crc_calc;
                data_stage2 <= data_stage1;
                valid_stage2 <= valid_stage1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 第三级流水线：CRC检查和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage2 <= {CRC_W{1'b0}};
            data_out <= {DATA_W{1'b0}};
            crc_error <= 1'b0;
        end else begin
            if (valid_stage2) begin
                crc_stage2 <= crc_stage1;
                data_out <= data_stage2;
                crc_error <= (crc_stage1 != 0);
            end else begin
                crc_error <= 1'b0;
            end
        end
    end
endmodule