//SystemVerilog
module CombDiv(
    input [3:0] D, d,
    output [3:0] q
);
    reg [3:0] quotient;
    reg [7:0] remainder;
    reg div_valid;
    
    // Division validity check
    always @(*) begin
        div_valid = (d != 0);
    end
    
    // Initialize division
    always @(*) begin
        remainder = {4'b0000, D};
        quotient = 4'b0000;
    end
    
    // Division step 1-4
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient[0] = 1'b1;
        end
    end
    
    // Division step 2-4
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 3-4
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 4-4
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 5-8
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 6-8
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 7-8
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 8-8
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 9-12
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 10-12
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 11-12
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 12-12
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 13-15
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 14-15
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    // Division step 15-15
    always @(*) begin
        if (div_valid && remainder >= {4'b0000, d}) begin
            remainder = remainder - {4'b0000, d};
            quotient = quotient + 1'b1;
        end
    end
    
    assign q = quotient;
endmodule