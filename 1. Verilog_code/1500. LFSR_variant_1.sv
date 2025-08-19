//SystemVerilog
module lfsr #(parameter [15:0] POLY = 16'h8016) (
    input wire clock, reset,
    output reg [15:0] lfsr_out,
    output reg sequence_bit
);
    reg [14:0] lfsr_internal;
    wire feedback;
    
    // Compute feedback using internal state plus the registered output bit
    assign feedback = ^({lfsr_out[15], lfsr_internal} & POLY);
    
    always @(posedge clock) begin
        lfsr_internal <= reset ? 15'h0000 : {lfsr_internal[13:0], feedback};
        lfsr_out <= reset ? 16'h0001 : {lfsr_internal, feedback};
        sequence_bit <= reset ? 1'b0 : lfsr_internal[14];
    end
endmodule