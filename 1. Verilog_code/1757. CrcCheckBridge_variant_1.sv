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
    reg [CRC_W-1:0] crc_calc;
    wire [CRC_W-1:0] next_crc;
    
    // 计算下一个CRC值，使用单独的赋值改善综合结果
    assign next_crc = {^{data_in, crc_calc}, {CRC_W-1{1'b0}}};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_calc <= {CRC_W{1'b0}};
            data_out <= {DATA_W{1'b0}};
            crc_error <= 1'b0;
        end else begin
            if (data_valid) begin
                crc_calc <= next_crc;
                data_out <= data_in;
            end
            // 将CRC错误检测改为使用OR归约，提高性能
            crc_error <= data_valid & (|crc_calc);
        end
    end
endmodule