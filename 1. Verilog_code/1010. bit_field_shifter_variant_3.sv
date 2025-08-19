//SystemVerilog
// Top-level bit field shifter with hierarchical structure
module bit_field_shifter(
    input  wire [31:0] data_in,
    input  wire [4:0]  field_start,
    input  wire [4:0]  field_width,
    input  wire [4:0]  shift_amount,
    input  wire        shift_dir,
    output reg  [31:0] data_out
);
    // Internal signals for inter-module connections
    wire [31:0] field_mask;
    wire [31:0] extracted_field;
    wire [31:0] shifted_field;
    wire [63:0] karatsuba_product;

    // Field mask generation
    field_mask_gen u_field_mask_gen (
        .field_width(field_width),
        .mask_out(field_mask)
    );

    // Field extraction
    field_extractor u_field_extractor (
        .data_in(data_in),
        .field_start(field_start),
        .field_mask(field_mask),
        .extracted_field(extracted_field)
    );

    // Field shifting (left/right selection)
    field_shifter u_field_shifter (
        .extracted_field(extracted_field),
        .shift_amount(shift_amount),
        .shift_dir(shift_dir),
        .shifted_field(shifted_field)
    );

    // Output multiplication (Karatsuba)
    karatsuba_32x32 u_karatsuba_32x32 (
        .a(shifted_field),
        .b(32'd1),
        .product(karatsuba_product)
    );

    always @(*) begin
        data_out = karatsuba_product[31:0];
    end

endmodule

// Field mask generator
// Generates a mask with 'field_width' LSB bits set to 1
module field_mask_gen(
    input  wire [4:0]  field_width,
    output reg  [31:0] mask_out
);
    always @(*) begin
        if (field_width == 0)
            mask_out = 32'b0;
        else if (field_width >= 32)
            mask_out = 32'hFFFFFFFF;
        else
            mask_out = (32'h1 << field_width) - 1;
    end
endmodule

// Field extractor
// Extracts a bit field from the input using field_start and field_mask
module field_extractor(
    input  wire [31:0] data_in,
    input  wire [4:0]  field_start,
    input  wire [31:0] field_mask,
    output wire [31:0] extracted_field
);
    assign extracted_field = (data_in >> field_start) & field_mask;
endmodule

// Field shifter
// Shifts the extracted field left or right by shift_amount based on shift_dir
module field_shifter(
    input  wire [31:0] extracted_field,
    input  wire [4:0]  shift_amount,
    input  wire        shift_dir, // 0: right, 1: left
    output wire [31:0] shifted_field
);
    wire [31:0] shifted_left;
    wire [31:0] shifted_right;

    barrel_shifter_left u_barrel_shifter_left (
        .data_in(extracted_field),
        .shift_amt(shift_amount),
        .data_out(shifted_left)
    );

    barrel_shifter_right u_barrel_shifter_right (
        .data_in(extracted_field),
        .shift_amt(shift_amount),
        .data_out(shifted_right)
    );

    assign shifted_field = shift_dir ? shifted_left : shifted_right;
endmodule

// Barrel shifter left
// Shifts input data left by shift_amt bits
module barrel_shifter_left(
    input  wire [31:0] data_in,
    input  wire [4:0]  shift_amt,
    output wire [31:0] data_out
);
    assign data_out = data_in << shift_amt;
endmodule

// Barrel shifter right
// Shifts input data right by shift_amt bits
module barrel_shifter_right(
    input  wire [31:0] data_in,
    input  wire [4:0]  shift_amt,
    output wire [31:0] data_out
);
    assign data_out = data_in >> shift_amt;
endmodule

// Karatsuba 32x32 multiplier
// Performs a 32x32 multiplication using a hierarchical Karatsuba algorithm
module karatsuba_32x32(
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [63:0] product
);
    wire [15:0] a_high = a[31:16];
    wire [15:0] a_low  = a[15:0];
    wire [15:0] b_high = b[31:16];
    wire [15:0] b_low  = b[15:0];

    wire [31:0] z0;
    wire [31:0] z1;
    wire [31:0] z2;

    // z0 = a_low * b_low
    karatsuba_16x16 u_karatsuba_16x16_z0 (
        .a(a_low),
        .b(b_low),
        .product(z0)
    );

    // z2 = a_high * b_high
    karatsuba_16x16 u_karatsuba_16x16_z2 (
        .a(a_high),
        .b(b_high),
        .product(z2)
    );

    // z1 = (a_low + a_high) * (b_low + b_high) - z2 - z0
    wire [16:0] sum_a = a_low + a_high;
    wire [16:0] sum_b = b_low + b_high;
    wire [33:0] z1_temp;

    karatsuba_17x17 u_karatsuba_17x17_z1 (
        .a(sum_a),
        .b(sum_b),
        .product(z1_temp)
    );
    assign z1 = z1_temp[31:0] - z2 - z0;

    // Combine results
    assign product = ({32'b0, z0}) + ({z1, 16'b0}) + ({z2, 32'b0});
endmodule

// Karatsuba 16x16 multiplier
// Performs a 16x16 multiplication using Karatsuba algorithm
module karatsuba_16x16(
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] product
);
    wire [7:0] a_high = a[15:8];
    wire [7:0] a_low  = a[7:0];
    wire [7:0] b_high = b[15:8];
    wire [7:0] b_low  = b[7:0];

    wire [15:0] z0;
    wire [15:0] z1;
    wire [15:0] z2;

    // z0 = a_low * b_low
    assign z0 = a_low * b_low;

    // z2 = a_high * b_high
    assign z2 = a_high * b_high;

    // z1 = (a_low + a_high) * (b_low + b_high) - z2 - z0
    wire [8:0] sum_a = a_low + a_high;
    wire [8:0] sum_b = b_low + b_high;
    wire [17:0] z1_temp;
    assign z1_temp = sum_a * sum_b;
    assign z1 = z1_temp[15:0] - z2 - z0;

    // Combine results
    assign product = ({16'b0, z0}) + ({z1, 8'b0}) + ({z2, 16'b0});
endmodule

// Karatsuba 17x17 multiplier
// Performs a 17x17 multiplication for Karatsuba intermediate calculation
module karatsuba_17x17(
    input  wire [16:0] a,
    input  wire [16:0] b,
    output wire [33:0] product
);
    wire [8:0] a_high = a[16:8];
    wire [8:0] a_low  = a[7:0];
    wire [8:0] b_high = b[16:8];
    wire [8:0] b_low  = b[7:0];

    wire [17:0] z0;
    wire [17:0] z1;
    wire [17:0] z2;

    // z0 = a_low * b_low
    assign z0 = a_low * b_low;

    // z2 = a_high * b_high
    assign z2 = a_high * b_high;

    // z1 = (a_low + a_high) * (b_low + b_high) - z2 - z0
    wire [9:0] sum_a = a_low + a_high;
    wire [9:0] sum_b = b_low + b_high;
    wire [19:0] z1_temp;
    assign z1_temp = sum_a * sum_b;
    assign z1 = z1_temp[17:0] - z2 - z0;

    // Combine results
    assign product = ({16'b0, z0}) + ({z1, 8'b0}) + ({z2, 16'b0});
endmodule