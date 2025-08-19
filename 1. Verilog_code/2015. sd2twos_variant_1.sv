//SystemVerilog
// Top-level module: sd2twos
// Function: Converts signed-digit (SD) code to two's complement representation
// Structure: Hierarchical, restructured for improved modularity and PPA

module sd2twos #(parameter W = 8) (
    input  wire [W-1:0] sd,
    output wire [W:0]   twos
);

    // Internal signals
    wire [W:0] signext_out;
    wire [W:0] twos_sum;

    // Sign Extension
    sd2twos_signext #(W) u_signext (
        .sd_in(sd),
        .sd_signext(signext_out)
    );

    // Adder
    sd2twos_adder #(W) u_adder (
        .sd_signext(signext_out),
        .sd(sd),
        .sum(twos_sum)
    );

    // Output assignment
    assign twos = twos_sum;

endmodule

// -----------------------------------------------------------------------------
// Submodule: sd2twos_signext
// Function: Sign-extends the most significant bit (MSB) of SD input to W+1 bits
// -----------------------------------------------------------------------------
module sd2twos_signext #(parameter W = 8) (
    input  wire [W-1:0] sd_in,
    output wire [W:0]   sd_signext
);
    // Sign-extend MSB of input and set lower W bits to zero
    assign sd_signext = {sd_in[W-1], {W{1'b0}}};
endmodule

// -----------------------------------------------------------------------------
// Submodule: sd2twos_adder
// Function: Adds sign-extended SD value to original SD code
// -----------------------------------------------------------------------------
module sd2twos_adder #(parameter W = 8) (
    input  wire [W:0] sd_signext, // sign extended MSB
    input  wire [W-1:0] sd,       // original SD code
    output wire [W:0] sum         // two's complement result
);
    // Addition of sign-extended MSB and input SD code (zero-extended to W+1)
    assign sum = sd_signext + {1'b0, sd};
endmodule