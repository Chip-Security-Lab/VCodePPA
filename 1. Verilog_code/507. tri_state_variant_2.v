module signed_multiplier_8bit(
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [15:0] product
);
    wire signed [7:0] a_abs;
    wire signed [7:0] b_abs;
    wire [15:0] abs_product;
    wire sign_bit;
    
    // Explicit multiplexer for a_abs
    assign a_abs = a[7] ? (~a + 1'b1) : a;
    
    // Explicit multiplexer for b_abs  
    assign b_abs = b[7] ? (~b + 1'b1) : b;
    
    // Multiplication
    assign abs_product = a_abs * b_abs;
    
    // Sign bit calculation
    assign sign_bit = a[7] ^ b[7];
    
    // Explicit multiplexer for final product
    assign product = sign_bit ? (~abs_product + 1'b1) : abs_product;
endmodule

module tri_state_controller(
    input data_in,
    input enable,
    output reg data_out
);
    always @(*) begin
        case(enable)
            1'b1: data_out = data_in;
            1'b0: data_out = 1'bz;
            default: data_out = 1'bz;
        endcase
    end
endmodule

module tri_state(
    input data_in,
    input enable,
    output tri data_out
);
    tri_state_controller controller_inst(
        .data_in(data_in),
        .enable(enable),
        .data_out(data_out)
    );
endmodule