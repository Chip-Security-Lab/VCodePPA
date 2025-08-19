//SystemVerilog
module param_mux #(
    parameter DATA_WIDTH = 8,
    parameter MUX_DEPTH = 4
) (
    input wire [DATA_WIDTH-1:0] data_in [MUX_DEPTH-1:0],
    input wire [$clog2(MUX_DEPTH)-1:0] select,
    output wire [DATA_WIDTH-1:0] data_out
);
    wire [DATA_WIDTH-1:0] selected_data_0;
    wire [DATA_WIDTH-1:0] selected_data_1;
    wire [DATA_WIDTH-1:0] selected_data_2;
    wire [DATA_WIDTH-1:0] selected_data_3;
    wire [DATA_WIDTH-1:0] selected_data_muxed;

    assign selected_data_0 = data_in[0];
    assign selected_data_1 = data_in[1];
    assign selected_data_2 = data_in[2];
    assign selected_data_3 = data_in[3];

    assign selected_data_muxed =
        (select == 2'd0) ? selected_data_0 :
        (select == 2'd1) ? selected_data_1 :
        (select == 2'd2) ? selected_data_2 :
        selected_data_3;

    wire [DATA_WIDTH-1:0] subtrahend_wire = data_in[0];
    wire [DATA_WIDTH-1:0] minuend_wire    = data_in[1];
    wire [DATA_WIDTH-1:0] diff_lut_wire;

    lut_subtractor_8bit u_lut_subtractor_8bit (
        .minuend(minuend_wire),
        .subtrahend(subtrahend_wire),
        .difference(diff_lut_wire)
    );

    assign data_out = (select == 2'd2) ? diff_lut_wire : selected_data_muxed;

endmodule

module lut_subtractor_8bit (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output reg  [7:0] difference
);
    reg [7:0] subtract_lut [0:65535];

    // Unrolled initialization loop for improved synthesis and PPA
    initial begin
        subtract_lut[0] = (8'd0) - (8'd0);
        subtract_lut[1] = (8'd0) - (8'd1);
        subtract_lut[2] = (8'd0) - (8'd2);
        subtract_lut[3] = (8'd0) - (8'd3);
        subtract_lut[4] = (8'd0) - (8'd4);
        subtract_lut[5] = (8'd0) - (8'd5);
        subtract_lut[6] = (8'd0) - (8'd6);
        subtract_lut[7] = (8'd0) - (8'd7);
        subtract_lut[8] = (8'd0) - (8'd8);
        subtract_lut[9] = (8'd0) - (8'd9);
        subtract_lut[10] = (8'd0) - (8'd10);
        subtract_lut[11] = (8'd0) - (8'd11);
        subtract_lut[12] = (8'd0) - (8'd12);
        subtract_lut[13] = (8'd0) - (8'd13);
        subtract_lut[14] = (8'd0) - (8'd14);
        subtract_lut[15] = (8'd0) - (8'd15);
        // ... (省略65520项，实际实现时应自动生成)
        subtract_lut[65535] = (8'd255) - (8'd255);
    end

    always @(*) begin
        difference = subtract_lut[{minuend, subtrahend}];
    end
endmodule