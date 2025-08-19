//SystemVerilog
module generate_mux #(
    parameter NUM_INPUTS = 16,
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data_in [0:NUM_INPUTS-1],
    input [$clog2(NUM_INPUTS)-1:0] sel,
    output reg [DATA_WIDTH-1:0] data_out
);

    always @(*) begin
        data_out = data_in[sel];
    end

endmodule