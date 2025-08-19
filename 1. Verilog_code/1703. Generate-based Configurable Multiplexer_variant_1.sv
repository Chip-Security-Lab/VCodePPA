//SystemVerilog
module generate_mux #(
    parameter NUM_INPUTS = 16,
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data_in [0:NUM_INPUTS-1],
    input [$clog2(NUM_INPUTS)-1:0] sel,
    output [DATA_WIDTH-1:0] data_out
);

    // Stage 1: Selection logic
    wire [DATA_WIDTH-1:0] selected_data [0:NUM_INPUTS-1];
    wire [DATA_WIDTH-1:0] stage1_out [0:NUM_INPUTS-1];
    
    genvar i;
    generate
        for (i = 0; i < NUM_INPUTS; i = i + 1) begin: sel_gen
            wire sel_match;
            assign sel_match = (sel == i);
            assign selected_data[i] = sel_match ? data_in[i] : {DATA_WIDTH{1'b0}};
        end
    endgenerate

    // Stage 2: Prefix computation
    wire [DATA_WIDTH-1:0] prefix_sum [0:NUM_INPUTS-1];
    wire [DATA_WIDTH-1:0] carry [0:NUM_INPUTS-1];
    
    genvar k;
    generate
        for (k = 0; k < NUM_INPUTS; k = k + 1) begin: prefix_gen
            if (k == 0) begin
                assign prefix_sum[0] = selected_data[0];
                assign carry[0] = {DATA_WIDTH{1'b0}};
            end else begin
                wire [DATA_WIDTH-1:0] temp_sum;
                wire [DATA_WIDTH-1:0] temp_carry;
                
                assign temp_sum = selected_data[k] ^ carry[k-1];
                assign temp_carry = (selected_data[k] & carry[k-1]) | 
                                  (selected_data[k] & prefix_sum[k-1]) | 
                                  (carry[k-1] & prefix_sum[k-1]);
                
                assign prefix_sum[k] = temp_sum;
                assign carry[k] = temp_carry;
            end
        end
    endgenerate

    // Final output
    assign data_out = prefix_sum[NUM_INPUTS-1];

endmodule