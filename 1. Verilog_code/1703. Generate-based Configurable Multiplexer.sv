module generate_mux #(
    parameter NUM_INPUTS = 16,
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data_in [0:NUM_INPUTS-1],
    input [$clog2(NUM_INPUTS)-1:0] sel,
    output [DATA_WIDTH-1:0] data_out
);
    wire [DATA_WIDTH-1:0] mux_stage [0:NUM_INPUTS-1];
    
    genvar i;
    generate
        for (i = 0; i < NUM_INPUTS; i = i + 1) begin: mux_gen
            assign mux_stage[i] = (sel == i) ? data_in[i] : {DATA_WIDTH{1'b0}};
        end
    endgenerate
    
    wire [DATA_WIDTH-1:0] or_result;
    assign or_result = {DATA_WIDTH{1'b0}};
    
    genvar j;
    generate
        for (j = 0; j < NUM_INPUTS; j = j + 1) begin: or_gen
            assign or_result = or_result | mux_stage[j];
        end
    endgenerate
    
    assign data_out = or_result;
endmodule