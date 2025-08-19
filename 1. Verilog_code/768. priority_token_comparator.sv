module priority_token_comparator #(
    parameter TOKEN_WIDTH = 8,
    parameter NUM_TOKENS = 4
)(
    input [TOKEN_WIDTH-1:0] input_token,
    input [TOKEN_WIDTH-1:0] token_array [0:NUM_TOKENS-1],
    input [NUM_TOKENS-1:0] token_valid,  // Indicates which tokens in the array are valid
    output reg match_found,
    output reg [1:0] match_index,        // Index of the highest priority matching token
    output reg [NUM_TOKENS-1:0] match_bitmap // Bitmap of all tokens that matched
);
    integer i;
    
    always @(*) begin
        // Default values
        match_found = 1'b0;
        match_index = 2'b00;
        match_bitmap = {NUM_TOKENS{1'b0}};
        
        // Check each token for a match and record in bitmap
        for (i = 0; i < NUM_TOKENS; i = i + 1) begin
            if (token_valid[i] && (input_token == token_array[i])) begin
                match_bitmap[i] = 1'b1;
            end
        end
        
        // Determine highest priority match (lowest index)
        match_found = |match_bitmap;
        
        if (match_bitmap[0])
            match_index = 2'd0;
        else if (match_bitmap[1])
            match_index = 2'd1;
        else if (match_bitmap[2])
            match_index = 2'd2;
        else if (match_bitmap[3])
            match_index = 2'd3;
    end
endmodule