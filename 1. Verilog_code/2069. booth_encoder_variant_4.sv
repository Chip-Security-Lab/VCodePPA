//SystemVerilog
// Top-level module using reusable Booth encoder cell
module booth_encoder #(parameter WIDTH = 4) (
    input  wire [WIDTH:0] multiplier_bits,  // 3 adjacent bits
    output wire [1:0]     booth_op,
    output wire           neg
);

    // Instantiate the reusable Booth cell
    booth_encoder_cell booth_cell_inst (
        .bits(multiplier_bits[2:0]),
        .booth_op(booth_op),
        .neg(neg)
    );

endmodule

// Reusable Booth encoder cell module
module booth_encoder_cell (
    input  wire [2:0] bits,
    output reg  [1:0] booth_op,
    output reg        neg
);
    always @(*) begin
        if ((bits == 3'b000) || (bits == 3'b111)) begin
            booth_op = 2'b00;
            neg = 1'b0;
        end else if ((bits == 3'b001) || (bits == 3'b010)) begin
            booth_op = 2'b01;
            neg = 1'b0;
        end else if ((bits == 3'b101) || (bits == 3'b110)) begin
            booth_op = 2'b01;
            neg = 1'b1;
        end else if (bits == 3'b011) begin
            booth_op = 2'b11;
            neg = 1'b0;
        end else if (bits == 3'b100) begin
            booth_op = 2'b11;
            neg = 1'b1;
        end else begin
            booth_op = 2'b00;
            neg = 1'b0;
        end
    end
endmodule