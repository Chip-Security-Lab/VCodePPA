//SystemVerilog

module simple_2to1_mux (
    input wire [7:0] data0, 
    input wire [7:0] data1,      // Data inputs
    input wire sel,              // Selection signal
    output wire [15:0] mux_out   // Output data (product)
);
    wire [15:0] product0;
    wire [15:0] product1;

    booth_multiplier_8x8 booth_mult0 (
        .multiplicand(data0),
        .multiplier(data1),
        .product(product0)
    );

    booth_multiplier_8x8 booth_mult1 (
        .multiplicand(data1),
        .multiplier(data0),
        .product(product1)
    );

    reg [15:0] mux_out_reg;

    always @(*) begin
        if (sel) begin
            mux_out_reg = product1;
        end else begin
            mux_out_reg = product0;
        end
    end

    assign mux_out = mux_out_reg;
endmodule

module booth_multiplier_8x8 (
    input wire [7:0] multiplicand,
    input wire [7:0] multiplier,
    output reg [15:0] product
);
    reg [15:0] booth_product;
    reg [8:0] booth_multiplier_ext;
    reg [7:0] booth_multiplicand;
    integer i;

    always @(*) begin
        booth_product = 16'b0;
        booth_multiplier_ext = {multiplier, 1'b0}; // Extend by 1 bit (Booth's algorithm)
        booth_multiplicand = multiplicand;

        for (i = 0; i < 8; i = i + 1) begin
            case (booth_multiplier_ext[1:0])
                2'b01: booth_product = booth_product + (booth_multiplicand << i);
                2'b10: booth_product = booth_product - (booth_multiplicand << i);
                default: booth_product = booth_product;
            endcase
            booth_multiplier_ext = booth_multiplier_ext >> 1;
        end
        product = booth_product;
    end
endmodule