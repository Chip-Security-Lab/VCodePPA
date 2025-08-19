//SystemVerilog
// SystemVerilog
module RedundantNOT(
    input  logic a,
    output logic y
);
    // Direct connection from input to output
    // Eliminated redundant NOT operations for improved performance
    assign y = a;
endmodule