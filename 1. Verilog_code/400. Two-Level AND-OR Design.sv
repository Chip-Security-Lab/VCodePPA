module nand2_20 (
    input wire A, B,
    output wire Y
);
    wire and_out;

    // Perform AND operation on inputs first
    and (and_out, A, B);
    or (Y, ~and_out, 1'b0); // OR with 1'b0 to negate the AND result
endmodule
