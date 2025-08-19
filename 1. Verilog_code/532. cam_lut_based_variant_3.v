module cam_lut_based #(parameter WIDTH=4, DEPTH=8)(
    input [WIDTH-1:0] search_key,
    output reg [DEPTH-1:0] hit_vector
);
    // Internal signal declarations
    wire is_valid_key;
    wire [2:0] key_index;
    reg [DEPTH-1:0] decoded_vector;
    reg [DEPTH-1:0] hit_vector_pipeline; // Pipeline register for output

    // Check if the search key is valid (less than 8)
    assign is_valid_key = (search_key < 4'h8);

    // Extract the lower 3 bits of the search key as the index
    assign key_index = search_key[2:0];

    // Independent decoder always block
    always @(*) begin
        decoded_vector = 8'b0; // Initialize decoded vector
        if (is_valid_key) begin
            decoded_vector[key_index] = 1'b1; // Set the hit bit
        end
    end

    // Pipeline stage to register the output
    always @(*) begin
        hit_vector_pipeline = decoded_vector; // Register the decoded vector
    end

    // Final output always block
    always @(*) begin
        hit_vector = hit_vector_pipeline; // Assign registered output to hit_vector
    end
endmodule