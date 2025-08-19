//SystemVerilog
// Top-level module
module hamming_16bit_enc_en(
    input clock, enable, clear,
    input [15:0] data_in,
    output reg [20:0] ham_out
);
    // Internal signals
    wire [3:0] parity_groups [0:4];
    
    // Parity calculation module
    parity_calculator parity_calc(
        .data_in(data_in),
        .parity_groups(parity_groups)
    );
    
    // Output assignment module
    output_assigner output_assign(
        .clock(clock),
        .enable(enable),
        .clear(clear),
        .data_in(data_in),
        .parity_groups(parity_groups),
        .ham_out(ham_out)
    );
endmodule

// Parity calculation module
module parity_calculator(
    input [15:0] data_in,
    output reg [3:0] parity_groups [0:4]
);
    always @(*) begin
        // First stage - calculate partial XORs in parallel
        parity_groups[0] = data_in[0] ^ data_in[2] ^ data_in[4] ^ data_in[6] ^ data_in[8] ^ data_in[10] ^ data_in[12] ^ data_in[14];
        parity_groups[1] = data_in[1] ^ data_in[2] ^ data_in[5] ^ data_in[6] ^ data_in[9] ^ data_in[10] ^ data_in[13] ^ data_in[14];
        parity_groups[2] = data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14];
        parity_groups[3] = data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14];
        parity_groups[4] = ^data_in;
    end
endmodule

// Output assignment module
module output_assigner(
    input clock, enable, clear,
    input [15:0] data_in,
    input [3:0] parity_groups [0:4],
    output reg [20:0] ham_out
);
    always @(posedge clock) begin
        if (clear) begin
            ham_out <= 21'b0;
        end
        else if (enable) begin
            // Assign parity bits
            ham_out[0] <= parity_groups[0];
            ham_out[1] <= parity_groups[1];
            ham_out[3] <= parity_groups[2];
            ham_out[7] <= parity_groups[3];
            ham_out[15] <= parity_groups[4];
            
            // Assign data bits
            ham_out[20:16] <= data_in[15:11];
            ham_out[14:8] <= data_in[10:4];
            ham_out[6:4] <= data_in[3:1];
            ham_out[2] <= data_in[0];
        end
    end
endmodule