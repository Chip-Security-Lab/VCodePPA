//SystemVerilog
module generate_mux #(
    parameter NUM_INPUTS = 16,
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data_in [0:NUM_INPUTS-1],
    input [$clog2(NUM_INPUTS)-1:0] sel,
    output [DATA_WIDTH-1:0] data_out
);
    
    reg [DATA_WIDTH-1:0] selected_data;
    
    integer k;
    always @(*) begin
        selected_data = {DATA_WIDTH{1'b0}};
        k = 0;
        while (k < NUM_INPUTS) begin
            if (sel == k) 
                selected_data = data_in[k];
            k = k + 1;
        end
    end
    
    assign data_out = selected_data;
endmodule