//SystemVerilog
module cascadable_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_in,
    input cascade_in_valid,
    input [$clog2(WIDTH)-1:0] cascade_in_idx,
    output cascade_out_valid,
    output [$clog2(WIDTH)-1:0] cascade_out_idx
);
    wire local_valid;
    wire [$clog2(WIDTH)-1:0] local_idx;
    
    // Local priority encoder with optimized structure
    assign local_valid = |data_in;
    
    // Improved priority encoder implementation
    reg [$clog2(WIDTH)-1:0] priority_index;
    
    integer i;
    always @(*) begin
        priority_index = {$clog2(WIDTH){1'b0}};
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (data_in[i]) begin
                priority_index = i[$clog2(WIDTH)-1:0];
            end
        end
    end
    
    assign local_idx = priority_index;
    
    // Cascade logic with explicit multiplexer
    assign cascade_out_valid = local_valid | cascade_in_valid;
    
    // Explicit multiplexer implementation replacing ternary operator
    wire sel;
    assign sel = local_valid;
    
    wire [$clog2(WIDTH)-1:0] mux_in0;
    wire [$clog2(WIDTH)-1:0] mux_in1;
    
    assign mux_in0 = cascade_in_idx;
    assign mux_in1 = local_idx;
    
    assign cascade_out_idx = sel ? mux_in1 : mux_in0;
endmodule