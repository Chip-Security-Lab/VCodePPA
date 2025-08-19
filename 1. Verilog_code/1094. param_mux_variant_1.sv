//SystemVerilog
module param_mux #(
    parameter DATA_WIDTH = 8,
    parameter MUX_DEPTH = 4
) (
    input wire [DATA_WIDTH-1:0] data_in [MUX_DEPTH-1:0],
    input wire [$clog2(MUX_DEPTH)-1:0] select,
    output wire [DATA_WIDTH-1:0] data_out
);
    // Unrolled 4:1 MUX logic for fixed MUX_DEPTH = 4
    wire [DATA_WIDTH-1:0] mux_data_0;
    wire [DATA_WIDTH-1:0] mux_data_1;
    wire [DATA_WIDTH-1:0] mux_data_2;
    wire [DATA_WIDTH-1:0] mux_data_3;

    assign mux_data_0 = data_in[0];
    assign mux_data_1 = data_in[1];
    assign mux_data_2 = data_in[2];
    assign mux_data_3 = data_in[3];

    assign data_out =
        (select == 2'd0) ? mux_data_0 :
        (select == 2'd1) ? mux_data_1 :
        (select == 2'd2) ? mux_data_2 :
        mux_data_3;
endmodule