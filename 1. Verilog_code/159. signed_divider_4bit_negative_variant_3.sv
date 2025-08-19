//SystemVerilog
// Top-level module
module signed_divider_4bit_negative (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] quotient,
    output signed [3:0] remainder
);
    // Internal signals
    wire [3:0] abs_a, abs_b;
    wire [3:0] abs_quotient, abs_remainder;
    wire a_sign, b_sign, result_sign;
    
    // Sign detection submodule
    sign_detector sign_detector_inst (
        .a(a),
        .b(b),
        .a_sign(a_sign),
        .b_sign(b_sign),
        .result_sign(result_sign)
    );
    
    // Absolute value conversion submodule
    abs_converter abs_converter_inst (
        .a(a),
        .b(b),
        .abs_a(abs_a),
        .abs_b(abs_b)
    );
    
    // Unsigned division submodule
    unsigned_divider_4bit unsigned_divider_inst (
        .a(abs_a),
        .b(abs_b),
        .quotient(abs_quotient),
        .remainder(abs_remainder)
    );
    
    // Result sign application submodule
    sign_applier sign_applier_inst (
        .abs_quotient(abs_quotient),
        .abs_remainder(abs_remainder),
        .result_sign(result_sign),
        .quotient(quotient),
        .remainder(remainder)
    );
endmodule

// Sign detection submodule
module sign_detector (
    input signed [3:0] a,
    input signed [3:0] b,
    output a_sign,
    output b_sign,
    output result_sign
);
    assign a_sign = a[3];
    assign b_sign = b[3];
    assign result_sign = a_sign ^ b_sign;
endmodule

// Absolute value conversion submodule
module abs_converter (
    input signed [3:0] a,
    input signed [3:0] b,
    output [3:0] abs_a,
    output [3:0] abs_b
);
    reg [3:0] abs_a_reg, abs_b_reg;
    
    always @(*) begin
        if (a[3]) begin
            abs_a_reg = -a;
        end else begin
            abs_a_reg = a;
        end
        
        if (b[3]) begin
            abs_b_reg = -b;
        end else begin
            abs_b_reg = b;
        end
    end
    
    assign abs_a = abs_a_reg;
    assign abs_b = abs_b_reg;
endmodule

// Unsigned division submodule
module unsigned_divider_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] quotient,
    output [3:0] remainder
);
    reg [3:0] q, r;
    reg [3:0] a_reg, b_reg;
    integer i;
    
    always @(*) begin
        a_reg = a;
        b_reg = b;
        q = 4'b0;
        r = 4'b0;
        
        for (i = 3; i >= 0; i = i - 1) begin
            r = {r[2:0], a_reg[i]};
            if (r >= b_reg) begin
                r = r - b_reg;
                q[i] = 1'b1;
            end else begin
                q[i] = 1'b0;
            end
        end
    end
    
    assign quotient = q;
    assign remainder = r;
endmodule

// Sign application submodule
module sign_applier (
    input [3:0] abs_quotient,
    input [3:0] abs_remainder,
    input result_sign,
    output signed [3:0] quotient,
    output signed [3:0] remainder
);
    reg signed [3:0] quotient_reg;
    
    always @(*) begin
        if (result_sign) begin
            quotient_reg = -abs_quotient;
        end else begin
            quotient_reg = abs_quotient;
        end
    end
    
    assign quotient = quotient_reg;
    assign remainder = abs_remainder;
endmodule