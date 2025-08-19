module ecc_parity #(
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data_in,
    input parity_in,
    output error_flag,
    output [DATA_WIDTH-1:0] data_corrected
);
wire calc_parity = ^data_in;
assign error_flag = calc_parity ^ parity_in;
assign data_corrected = error_flag ? ~data_in : data_in;
endmodule