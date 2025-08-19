// Top level module
module bcd_to_7seg(
    input [3:0] bcd,
    output [6:0] seg
);

    // Internal signals
    wire [6:0] seg_pattern;
    wire valid_bcd;
    
    // BCD validation module
    bcd_validator bcd_valid_inst(
        .bcd(bcd),
        .valid(valid_bcd)
    );
    
    // Pattern decoder module  
    pattern_decoder pattern_dec_inst(
        .bcd(bcd),
        .pattern(seg_pattern)
    );
    
    // Output control module
    output_control output_ctrl_inst(
        .pattern(seg_pattern),
        .valid(valid_bcd),
        .seg(seg)
    );

endmodule

// BCD validation module
module bcd_validator(
    input [3:0] bcd,
    output reg valid
);
    // BCD range validation logic
    always @(*) begin
        valid = (bcd <= 4'd9);
    end
endmodule

// Pattern decoder module
module pattern_decoder(
    input [3:0] bcd,
    output reg [6:0] pattern
);
    // Segment A control
    always @(*) begin
        case(bcd)
            4'd0, 4'd2, 4'd3, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9: pattern[6] = 1'b0;
            4'd1, 4'd4: pattern[6] = 1'b1;
            default: pattern[6] = 1'b0;
        endcase
    end

    // Segment B control
    always @(*) begin
        case(bcd)
            4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd7, 4'd8, 4'd9: pattern[5] = 1'b0;
            4'd5, 4'd6: pattern[5] = 1'b1;
            default: pattern[5] = 1'b0;
        endcase
    end

    // Segment C control
    always @(*) begin
        case(bcd)
            4'd0, 4'd1, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9: pattern[4] = 1'b0;
            4'd2: pattern[4] = 1'b1;
            default: pattern[4] = 1'b0;
        endcase
    end

    // Segment D control
    always @(*) begin
        case(bcd)
            4'd0, 4'd2, 4'd3, 4'd5, 4'd6, 4'd8, 4'd9: pattern[3] = 1'b0;
            4'd1, 4'd4, 4'd7: pattern[3] = 1'b1;
            default: pattern[3] = 1'b0;
        endcase
    end

    // Segment E control
    always @(*) begin
        case(bcd)
            4'd0, 4'd2, 4'd6, 4'd8: pattern[2] = 1'b0;
            4'd1, 4'd3, 4'd4, 4'd5, 4'd7, 4'd9: pattern[2] = 1'b1;
            default: pattern[2] = 1'b0;
        endcase
    end

    // Segment F control
    always @(*) begin
        case(bcd)
            4'd0, 4'd4, 4'd5, 4'd6, 4'd8, 4'd9: pattern[1] = 1'b0;
            4'd1, 4'd2, 4'd3, 4'd7: pattern[1] = 1'b1;
            default: pattern[1] = 1'b0;
        endcase
    end

    // Segment G control
    always @(*) begin
        case(bcd)
            4'd0, 4'd1, 4'd7: pattern[0] = 1'b0;
            4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd8, 4'd9: pattern[0] = 1'b1;
            default: pattern[0] = 1'b0;
        endcase
    end
endmodule

// Output control module
module output_control(
    input [6:0] pattern,
    input valid,
    output reg [6:0] seg
);
    // Output enable control
    always @(*) begin
        seg = valid ? pattern : 7'b0000000;
    end
endmodule