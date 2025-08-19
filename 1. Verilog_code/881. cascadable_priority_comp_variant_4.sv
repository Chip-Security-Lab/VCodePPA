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
    reg [$clog2(WIDTH)-1:0] borrow_idx;
    reg borrow_valid;
    reg [WIDTH-1:0] borrow_data;
    
    // Local priority encoder using borrow-based algorithm
    assign local_valid = |data_in;
    
    // Borrow-based priority encoding
    always @(*) begin
        borrow_data = data_in;
        borrow_idx = 0;
        borrow_valid = 0;
        
        // Iterative borrow-based approach
        for (integer i = WIDTH-1; i >= 0; i = i - 1) begin
            if (borrow_data[i]) begin
                borrow_idx = i[$clog2(WIDTH)-1:0];
                borrow_valid = 1;
                // Clear all lower bits to optimize next iterations
                for (integer j = 0; j < i; j = j + 1)
                    borrow_data[j] = 0;
            end
        end
    end
    
    assign local_idx = borrow_idx;
    
    // Cascade logic
    assign cascade_out_valid = local_valid || cascade_in_valid;
    assign cascade_out_idx = local_valid ? local_idx : cascade_in_idx;
endmodule