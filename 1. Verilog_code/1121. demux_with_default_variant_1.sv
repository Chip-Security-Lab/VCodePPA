//SystemVerilog
module demux_with_default (
    input wire data_in,                  // Input data
    input wire [2:0] sel_addr,           // Selection address
    output reg [6:0] outputs,            // Normal outputs
    output reg default_out               // Default output for invalid addresses
);
    wire [6:0] karatsuba_result;
    wire [6:0] one_hot_sel;

    // Karatsuba multiplier for 3-bit by 3-bit to generate 7-bit one-hot signal
    karatsuba_multiplier_3x3 u_karatsuba_sel (
        .a({1'b0, sel_addr}), // Pad sel_addr to 4 bits for 3x3 mult
        .b(7'b0000001),
        .product(one_hot_sel)
    );

    always @(*) begin
        outputs = 7'b0;
        default_out = 1'b0;

        if (sel_addr <= 3'b110) begin
            outputs = one_hot_sel & {7{data_in}};
        end else begin
            default_out = data_in;
        end
    end
endmodule

// Karatsuba multiplier for 3x3 bits, output 7 bits
module karatsuba_multiplier_3x3 (
    input  wire [3:0] a, // Only [2:0] used
    input  wire [6:0] b, // Always 7'b0000001 for one-hot
    output wire [6:0] product
);
    wire [1:0] a_low;
    wire a_high;
    wire [1:0] b_low;
    wire [4:0] b_high;

    assign a_low = a[1:0];
    assign a_high = a[2];
    assign b_low = b[1:0];
    assign b_high = b[6:2];

    // Partial products
    wire [3:0] z0;
    wire [4:0] z2;
    wire [2:0] sum_ab_low;
    wire sum_ab_high;
    wire [2:0] sum_ab;
    wire [6:0] z1;

    reg [3:0] z0_reg;
    reg [4:0] z2_reg;
    reg [6:0] z1_reg;

    // z0 logic
    always @(*) begin
        if (a_low[0]) begin
            if (a_low[1]) begin
                z0_reg = b_low + {b_low,1'b0};
            end else begin
                z0_reg = b_low;
            end
        end else begin
            if (a_low[1]) begin
                z0_reg = {b_low,1'b0};
            end else begin
                z0_reg = 4'b0;
            end
        end
    end

    // z2 logic
    always @(*) begin
        if (a_high) begin
            z2_reg = b_high;
        end else begin
            z2_reg = 5'b0;
        end
    end

    assign sum_ab = {a_high, a_low};

    // z1 logic
    always @(*) begin
        if (sum_ab != 3'b000) begin
            z1_reg = b;
        end else begin
            z1_reg = 7'b0;
        end
    end

    assign z0 = z0_reg;
    assign z2 = z2_reg;
    assign z1 = z1_reg;

    assign product = {z2,2'b00} + {z1[4:0],2'b0} + z0;
endmodule