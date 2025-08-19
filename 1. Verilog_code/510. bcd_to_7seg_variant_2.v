// Top-level module
module bcd_to_7seg_top(
    input [3:0] bcd,
    output [6:0] seg
);
    // Internal signals
    wire [6:0] seg_pattern;
    wire valid_bcd;
    
    // Instantiate BCD validation module
    bcd_validator bcd_validator_inst(
        .bcd(bcd),
        .valid(valid_bcd)
    );
    
    // Instantiate pattern decoder module
    bcd_pattern_decoder pattern_decoder_inst(
        .bcd(bcd),
        .pattern(seg_pattern)
    );
    
    // Instantiate output control module
    seg_output_control output_control_inst(
        .pattern(seg_pattern),
        .valid_bcd(valid_bcd),
        .seg(seg)
    );
endmodule

// BCD validation module
module bcd_validator(
    input [3:0] bcd,
    output valid
);
    // Valid BCD is 0-9 (0-1001 in binary)
    assign valid = (bcd <= 4'd9);
endmodule

// Pattern decoder module
module bcd_pattern_decoder(
    input [3:0] bcd,
    output reg [6:0] pattern
);
    // Segment pattern for each BCD digit
    // Segments: abcdefg (7 segments)
    always @(*) begin
        case(bcd)
            4'd0: pattern = 7'b0111111;  // 0
            4'd1: pattern = 7'b0000110;  // 1
            4'd2: pattern = 7'b1011011;  // 2
            4'd3: pattern = 7'b1001111;  // 3
            4'd4: pattern = 7'b1100110;  // 4
            4'd5: pattern = 7'b1101101;  // 5
            4'd6: pattern = 7'b1111101;  // 6
            4'd7: pattern = 7'b0000111;  // 7
            4'd8: pattern = 7'b1111111;  // 8
            4'd9: pattern = 7'b1101111;  // 9
            default: pattern = 7'b0000000;  // Default pattern
        endcase
    end
endmodule

// Output control module
module seg_output_control(
    input [6:0] pattern,
    input valid_bcd,
    output reg [6:0] seg
);
    // Output control logic
    always @(*) begin
        if (valid_bcd) begin
            seg = pattern;
        end else begin
            seg = 7'b0000000;
        end
    end
endmodule