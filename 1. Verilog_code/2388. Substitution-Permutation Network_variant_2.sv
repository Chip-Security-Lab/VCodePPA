//SystemVerilog
module sub_perm_network #(parameter BLOCK_SIZE = 16) (
    input wire clock, reset_b, process,
    input wire [BLOCK_SIZE-1:0] block_in, key,
    output reg [BLOCK_SIZE-1:0] block_out,
    output reg done
);
    // Simple substitution (nibble-wise)
    function [3:0] sbox(input [3:0] nibble);
        begin
            case(nibble)
                4'h0: sbox = 4'hC; 4'h1: sbox = 4'h5; 4'h2: sbox = 4'h6; 4'h3: sbox = 4'hB;
                4'h4: sbox = 4'h9; 4'h5: sbox = 4'h0; 4'h6: sbox = 4'hA; 4'h7: sbox = 4'hD;
                4'h8: sbox = 4'h3; 4'h9: sbox = 4'hE; 4'hA: sbox = 4'hF; 4'hB: sbox = 4'h8;
                4'hC: sbox = 4'h4; 4'hD: sbox = 4'h7; 4'hE: sbox = 4'h1; 4'hF: sbox = 4'h2;
            endcase
        end
    endfunction
    
    reg [BLOCK_SIZE-1:0] state;
    reg [BLOCK_SIZE-1:0] sbox_inputs;
    reg process_state;
    
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            state <= 0;
            sbox_inputs <= 0;
            process_state <= 0;
            done <= 0;
            block_out <= 0;
        end else begin
            if (process) begin
                // Round 1: Key mixing
                state <= block_in ^ key;
                process_state <= 1;
                done <= 0;
            end else if (process_state && !done) begin
                // Capture the inputs to the S-box (moved register backward)
                for (integer i = 0; i < BLOCK_SIZE/4; i = i + 1)
                    sbox_inputs[i*4+:4] <= state[(i*4+4)%BLOCK_SIZE+:4];
                process_state <= 0;
                done <= 1;
            end
        end
    end
    
    // Separate always block for S-box computation
    // This moves the register backward through the combinational logic
    always @(*) begin
        for (integer i = 0; i < BLOCK_SIZE/4; i = i + 1)
            block_out[i*4+:4] = sbox(sbox_inputs[i*4+:4]);
    end
endmodule