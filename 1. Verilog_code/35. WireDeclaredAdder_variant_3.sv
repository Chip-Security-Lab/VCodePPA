//SystemVerilog
module adder_8bit_rca (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire       cin,
    output wire [7:0] sum,
    output wire      cout
);

// Internal wire for ripple carries
wire [8:0] carry;

// Assign the input carry to the first stage's carry-in
assign carry[0] = cin;

// Generate 8 full adder stages
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : full_adder_stage
        // Full adder logic for bit i
        assign sum[i] = a[i] ^ b[i] ^ carry[i];
        assign carry[i+1] = (a[i] & b[i]) | (carry[i] & (a[i] ^ b[i]));
    end
endgenerate

// Assign the final carry-out
assign cout = carry[8];

endmodule