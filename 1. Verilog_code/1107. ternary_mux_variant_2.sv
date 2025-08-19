//SystemVerilog
module ternary_mux (
    input wire [1:0] selector,    // Selection control
    input wire [7:0] input_a, input_b, input_c, input_d, // Inputs
    output wire [15:0] mux_out     // Output result (updated to 16 bits for multiplication result)
);
    wire [7:0] selected_input_x;
    wire [7:0] selected_input_y;
    reg [7:0] selected_x_reg, selected_y_reg;
    wire [15:0] karatsuba_result;

    // Select two inputs based on selector for multiplication
    always @(*) begin
        case (selector)
            2'b00: begin
                selected_x_reg = input_a;
                selected_y_reg = input_b;
            end
            2'b01: begin
                selected_x_reg = input_b;
                selected_y_reg = input_c;
            end
            2'b10: begin
                selected_x_reg = input_c;
                selected_y_reg = input_d;
            end
            default: begin
                selected_x_reg = input_d;
                selected_y_reg = input_a;
            end
        endcase
    end

    assign selected_input_x = selected_x_reg;
    assign selected_input_y = selected_y_reg;

    // Instantiate the Karatsuba multiplier
    karatsuba_mult_8 karatsuba_mult_inst (
        .multiplicand(selected_input_x),
        .multiplier(selected_input_y),
        .product(karatsuba_result)
    );

    assign mux_out = karatsuba_result;

endmodule

// Recursive Karatsuba multiplier for 8-bit operands
module karatsuba_mult_8 (
    input wire [7:0] multiplicand,
    input wire [7:0] multiplier,
    output wire [15:0] product
);
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] z0, z2;
    wire [8:0] a_sum, b_sum;
    wire [15:0] z1_temp;
    wire [7:0] z1_partial;
    wire [15:0] z1;

    assign a_high = multiplicand[7:4];
    assign a_low  = multiplicand[3:0];
    assign b_high = multiplier[7:4];
    assign b_low  = multiplier[3:0];

    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;

    // Recursive calls for 4-bit Karatsuba multipliers
    karatsuba_mult_4 karatsuba_mult_4_z0 (
        .multiplicand(a_low),
        .multiplier(b_low),
        .product(z0)
    );

    karatsuba_mult_4 karatsuba_mult_4_z2 (
        .multiplicand(a_high),
        .multiplier(b_high),
        .product(z2)
    );

    karatsuba_mult_4 karatsuba_mult_4_z1 (
        .multiplicand(a_sum[3:0]),
        .multiplier(b_sum[3:0]),
        .product(z1_partial)
    );

    // z1 = (a_low + a_high) * (b_low + b_high) - z2 - z0
    assign z1_temp = {8'b0, z1_partial} - {8'b0, z2} - {8'b0, z0};
    assign z1 = z1_temp[7:0];

    // product = z2 << 8 + z1 << 4 + z0
    assign product = ({z2, 8'b0}) + ({z1, 4'b0}) + {8'b0, z0};

endmodule

// Recursive Karatsuba multiplier for 4-bit operands
module karatsuba_mult_4 (
    input wire [3:0] multiplicand,
    input wire [3:0] multiplier,
    output wire [7:0] product
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] z0, z2;
    wire [2:0] a_sum, b_sum;
    wire [7:0] z1_temp;
    wire [3:0] z1_partial;
    wire [7:0] z1;

    assign a_high = multiplicand[3:2];
    assign a_low  = multiplicand[1:0];
    assign b_high = multiplier[3:2];
    assign b_low  = multiplier[1:0];

    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;

    // Recursive calls for 2-bit Karatsuba multipliers
    karatsuba_mult_2 karatsuba_mult_2_z0 (
        .multiplicand(a_low),
        .multiplier(b_low),
        .product(z0)
    );

    karatsuba_mult_2 karatsuba_mult_2_z2 (
        .multiplicand(a_high),
        .multiplier(b_high),
        .product(z2)
    );

    karatsuba_mult_2 karatsuba_mult_2_z1 (
        .multiplicand(a_sum[1:0]),
        .multiplier(b_sum[1:0]),
        .product(z1_partial)
    );

    // z1 = (a_low + a_high) * (b_low + b_high) - z2 - z0
    assign z1_temp = {4'b0, z1_partial} - {4'b0, z2} - {4'b0, z0};
    assign z1 = z1_temp[3:0];

    // product = z2 << 4 + z1 << 2 + z0
    assign product = ({z2, 4'b0}) + ({z1, 2'b0}) + {4'b0, z0};

endmodule

// Base case: 2-bit multiplier (use direct multiplication)
module karatsuba_mult_2 (
    input wire [1:0] multiplicand,
    input wire [1:0] multiplier,
    output wire [3:0] product
);
    assign product = multiplicand * multiplier;
endmodule