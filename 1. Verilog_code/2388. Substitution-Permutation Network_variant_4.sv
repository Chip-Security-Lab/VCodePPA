//SystemVerilog
module sub_perm_network #(parameter BLOCK_SIZE = 16) (
    input wire clock, reset_b, process,
    input wire [BLOCK_SIZE-1:0] block_in, key,
    output reg [BLOCK_SIZE-1:0] block_out,
    output reg done
);
    // Optimized substitution box implementation
    function [3:0] sbox(input [3:0] nibble);
        reg [3:0] result;
        begin
            case(nibble)
                4'h0: result = 4'hC;
                4'h1: result = 4'h5;
                4'h2: result = 4'h6;
                4'h3: result = 4'hB;
                4'h4: result = 4'h9;
                4'h5: result = 4'h0;
                4'h6: result = 4'hA;
                4'h7: result = 4'hD;
                4'h8: result = 4'h3;
                4'h9: result = 4'hE;
                4'hA: result = 4'hF;
                4'hB: result = 4'h8;
                4'hC: result = 4'h4;
                4'hD: result = 4'h7;
                4'hE: result = 4'h1;
                4'hF: result = 4'h2;
                default: result = 4'h0;
            endcase
            sbox = result;
        end
    endfunction
    
    // State registers with proper reset values
    reg [BLOCK_SIZE-1:0] mixed_state;
    reg processing;
    reg process_d1;
    
    // Optimized key mixing operation
    wire [BLOCK_SIZE-1:0] key_mixed = block_in ^ key;
    
    // Improved S-box implementation with constant index calculation
    wire [3:0] sbox_inputs[0:BLOCK_SIZE/4-1];
    wire [3:0] sbox_results[0:BLOCK_SIZE/4-1];
    
    genvar i;
    generate
        for (i = 0; i < BLOCK_SIZE/4; i = i + 1) begin : sbox_mapping
            // Pre-calculate the rotation index at compile time
            localparam integer idx = (i*4+4) % BLOCK_SIZE;
            
            // Extract the nibble from key_mixed
            assign sbox_inputs[i] = key_mixed[idx+:4];
            
            // Apply S-box transformation
            assign sbox_results[i] = sbox(sbox_inputs[i]);
        end
    endgenerate
    
    // FSM with synchronous reset for better timing
    always @(posedge clock) begin
        if (!reset_b) begin
            mixed_state <= {BLOCK_SIZE{1'b0}};
            process_d1 <= 1'b0;
            processing <= 1'b0;
            block_out <= {BLOCK_SIZE{1'b0}};
            done <= 1'b0;
        end 
        else begin
            // Edge detection for process signal
            process_d1 <= process;
            
            if (process && !process_d1) begin
                // Rising edge of process signal
                mixed_state <= key_mixed;
                processing <= 1'b1;
                done <= 1'b0;
            end 
            else if (processing) begin
                // Single-cycle operation for better performance
                processing <= 1'b0;
                done <= 1'b1;
                
                // Parallel assignment of all nibbles for faster operation
                for (integer j = 0; j < BLOCK_SIZE/4; j = j + 1) begin
                    block_out[j*4+:4] <= sbox_results[j];
                end
            end
            else if (done && !process) begin
                // Reset done signal when process goes low
                done <= 1'b0;
            end
        end
    end
endmodule