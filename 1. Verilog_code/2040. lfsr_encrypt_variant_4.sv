//SystemVerilog
module lfsr_encrypt #(parameter SEED=8'hFF, POLY=8'h1D) (
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] encrypted
);

    reg [7:0] lfsr;
    wire feedback;
    wire [7:0] next_lfsr;

    // Feedback calculation for LFSR
    assign feedback = lfsr[7];

    // Next state logic for LFSR
    assign next_lfsr = (feedback) ? ((lfsr << 1) ^ POLY) : (lfsr << 1);

    // LFSR state register
    // Handles LFSR update and reset
    always @(posedge clk or negedge rst_n) begin : lfsr_state_block
        if (!rst_n) begin
            lfsr <= SEED;
        end else begin
            lfsr <= next_lfsr;
        end
    end

    // Encryption output register
    // Handles encrypted output update and reset
    always @(posedge clk or negedge rst_n) begin : encrypted_output_block
        if (!rst_n) begin
            encrypted <= 8'd0;
        end else begin
            encrypted <= data_in ^ lfsr;
        end
    end

endmodule