//SystemVerilog
module onehot_left_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [WIDTH-1:0] one_hot_control, // One-hot encoded shift amount
    output [WIDTH-1:0] out_data
);
    // Manchester carry chain implementation for left shifter
    wire [WIDTH-1:0] shift_stages [WIDTH:0];
    wire [WIDTH-1:0] prop_signals;
    wire [WIDTH:0] gen_signals;
    
    // Initialize first stage with input data
    assign shift_stages[0] = in_data;
    
    // Generate propagate signals
    genvar i, j;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_stage
            // Generate block for each shift stage
            if (i > 0) begin
                assign gen_signals[i] = one_hot_control[i-1];
                
                // Create shift_stages for each potential shift amount
                for (j = 0; j < WIDTH; j = j + 1) begin: shift_bit
                    if (j < i) begin
                        assign shift_stages[i][j] = 1'b0; // Shifted in zeros
                    end else begin
                        assign shift_stages[i][j] = shift_stages[i-1][j-i];
                    end
                end
            end
        end
    endgenerate
    
    // Final stage selection using Manchester carry chain concept
    reg [WIDTH-1:0] result;
    integer k, m;
    
    always @(*) begin
        result = shift_stages[0]; // Default is no shift
        
        // Priority selection using carry-chain concept
        for (k = 1; k <= WIDTH; k = k + 1) begin
            if (one_hot_control[k-1]) begin
                result = shift_stages[k];
            end
        end
    end
    
    assign out_data = result;
endmodule