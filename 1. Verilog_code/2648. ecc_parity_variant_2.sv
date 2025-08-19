//SystemVerilog
module ecc_parity #(
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data_in,
    input parity_in,
    output error_flag,
    output [DATA_WIDTH-1:0] data_corrected
);
    wire parity_error = ^data_in ^ parity_in;
    assign error_flag = parity_error;
    
    // 使用补码加法实现减法
    wire [DATA_WIDTH-1:0] complement_data_in = ~data_in + 1'b1; // 计算data_in的补码
    assign data_corrected = {DATA_WIDTH{parity_error}} ^ complement_data_in; // 使用补码进行加法

endmodule