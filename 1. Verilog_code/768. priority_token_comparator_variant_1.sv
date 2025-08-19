//SystemVerilog
module priority_token_comparator #(
    parameter TOKEN_WIDTH = 8,
    parameter NUM_TOKENS = 4
)(
    input [TOKEN_WIDTH-1:0] input_token,
    input [TOKEN_WIDTH-1:0] token_array [0:NUM_TOKENS-1],
    input [NUM_TOKENS-1:0] token_valid,
    output reg match_found,
    output reg [1:0] match_index,
    output reg [NUM_TOKENS-1:0] match_bitmap
);

    integer i, j;
    reg is_equal;
    reg [TOKEN_WIDTH-1:0] a, b;
    reg borrow;
    reg [TOKEN_WIDTH-1:0] diff;
    
    always @(*) begin
        match_found = 1'b0;
        match_index = 2'b00;
        match_bitmap = {NUM_TOKENS{1'b0}};
        
        for (i = 0; i < NUM_TOKENS; i = i + 1) begin
            a = input_token;
            b = token_array[i];
            borrow = 0;
            diff = 0;
            
            diff[0] = a[0] ^ b[0] ^ borrow;
            borrow = (~a[0] & b[0]) | (borrow & ~(a[0] ^ b[0]));
            
            diff[1] = a[1] ^ b[1] ^ borrow;
            borrow = (~a[1] & b[1]) | (borrow & ~(a[1] ^ b[1]));
            
            for (j = 2; j < TOKEN_WIDTH; j = j + 1) begin
                diff[j] = a[j] ^ b[j] ^ borrow;
                borrow = (~a[j] & b[j]) | (borrow & ~(a[j] ^ b[j]));
            end
            
            is_equal = (diff == {TOKEN_WIDTH{1'b0}});
            
            if (token_valid[i] && is_equal) begin
                match_bitmap[i] = 1'b1;
            end
        end
        
        match_found = |match_bitmap;
        
        if (match_bitmap[0]) begin
            match_index = 2'd0;
        end else if (match_bitmap[1]) begin
            match_index = 2'd1;
        end else if (match_bitmap[2]) begin
            match_index = 2'd2;
        end else if (match_bitmap[3]) begin
            match_index = 2'd3;
        end else begin
            match_index = 2'd0;
        end
    end
endmodule