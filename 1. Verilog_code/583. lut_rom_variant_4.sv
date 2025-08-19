//SystemVerilog
// Top level module
module booth_multiplier_top(
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output [15:0] product
);

    wire [7:0] booth_pp [0:3];
    wire [7:0] booth_pp_neg [0:3];
    wire [15:0] booth_sum;

    // Booth encoder instances
    booth_encoder booth_enc0 (
        .multiplicand(multiplicand),
        .mult_bits(multiplier[1:0]),
        .pp(booth_pp[0]),
        .pp_neg(booth_pp_neg[0])
    );

    booth_encoder booth_enc1 (
        .multiplicand(multiplicand),
        .mult_bits(multiplier[3:2]),
        .pp(booth_pp[1]),
        .pp_neg(booth_pp_neg[1])
    );

    booth_encoder booth_enc2 (
        .multiplicand(multiplicand),
        .mult_bits(multiplier[5:4]),
        .pp(booth_pp[2]),
        .pp_neg(booth_pp_neg[2])
    );

    booth_encoder booth_enc3 (
        .multiplicand(multiplicand),
        .mult_bits(multiplier[7:6]),
        .pp(booth_pp[3]),
        .pp_neg(booth_pp_neg[3])
    );

    // Partial product accumulator
    booth_accumulator acc (
        .pp(booth_pp),
        .pp_neg(booth_pp_neg),
        .sum(booth_sum)
    );

    // Output register
    assign product = booth_sum;

endmodule

// Booth encoder submodule
module booth_encoder(
    input [7:0] multiplicand,
    input [1:0] mult_bits,
    output reg [7:0] pp,
    output reg [7:0] pp_neg
);

    always @(*) begin
        case (mult_bits)
            2'b01: begin
                pp = multiplicand;
                pp_neg = 8'b0;
            end
            2'b10: begin
                pp = {multiplicand[6:0], 1'b0};
                pp_neg = multiplicand;
            end
            2'b11: begin
                pp = 8'b0;
                pp_neg = multiplicand;
            end
            default: begin
                pp = 8'b0;
                pp_neg = 8'b0;
            end
        endcase
    end

endmodule

// Partial product accumulator submodule
module booth_accumulator(
    input [7:0] pp [0:3],
    input [7:0] pp_neg [0:3],
    output reg [15:0] sum
);

    always @(*) begin
        sum = {8'b0, pp[0]} - {8'b0, pp_neg[0]} +
              ({7'b0, pp[1], 1'b0} - {7'b0, pp_neg[1], 1'b0}) +
              ({6'b0, pp[2], 2'b0} - {6'b0, pp_neg[2], 2'b0}) +
              ({5'b0, pp[3], 3'b0} - {5'b0, pp_neg[3], 3'b0});
    end

endmodule

// LUT ROM module
module lut_rom (
    input [3:0] addr,
    output reg [7:0] data
);
    always @(*) begin
        case (addr)
            4'h0: data = 8'hA1;
            4'h1: data = 8'hB2;
            4'h2: data = 8'hC3;
            4'h3: data = 8'hD4;
            4'h4: data = 8'hE5;
            4'h5: data = 8'hF6;
            4'h6: data = 8'h07;
            4'h7: data = 8'h18;
            default: data = 8'h00;
        endcase
    end
endmodule