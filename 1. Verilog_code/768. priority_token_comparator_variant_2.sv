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

    // LUT for 2-bit subtraction
    reg [3:0] sub_lut [0:15];
    reg [TOKEN_WIDTH-1:0] diff [0:NUM_TOKENS-1];
    reg [NUM_TOKENS-1:0] match_temp;
    integer i;

    // Initialize LUT for 2-bit subtraction
    initial begin
        sub_lut[0] = 4'b0000;  // 0-0
        sub_lut[1] = 4'b1111;  // 0-1
        sub_lut[2] = 4'b1110;  // 0-2
        sub_lut[3] = 4'b1101;  // 0-3
        sub_lut[4] = 4'b0001;  // 1-0
        sub_lut[5] = 4'b0000;  // 1-1
        sub_lut[6] = 4'b1111;  // 1-2
        sub_lut[7] = 4'b1110;  // 1-3
        sub_lut[8] = 4'b0010;  // 2-0
        sub_lut[9] = 4'b0001;  // 2-1
        sub_lut[10] = 4'b0000; // 2-2
        sub_lut[11] = 4'b1111; // 2-3
        sub_lut[12] = 4'b0011; // 3-0
        sub_lut[13] = 4'b0010; // 3-1
        sub_lut[14] = 4'b0001; // 3-2
        sub_lut[15] = 4'b0000; // 3-3
    end

    always @(*) begin
        match_found = 1'b0;
        match_index = 2'b00;
        match_bitmap = {NUM_TOKENS{1'b0}};
        match_temp = {NUM_TOKENS{1'b0}};

        for (i = 0; i < NUM_TOKENS; i = i + 1) begin
            if (token_valid[i]) begin
                // Use LUT-based subtraction for 2-bit comparison
                diff[i] = sub_lut[{input_token[1:0], token_array[i][1:0]}];
                if (diff[i] == 0) begin
                    match_temp[i] = 1'b1;
                end
            end
        end

        match_bitmap = match_temp;
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