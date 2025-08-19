//SystemVerilog
//-----------------------------------------------------------------------------
// File: sub_perm_network.v
// Description: Top level module for substitution-permutation network (Pipelined)
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
module sub_perm_network #(parameter BLOCK_SIZE = 16) (
    input wire clock, reset_b, process,
    input wire [BLOCK_SIZE-1:0] block_in, key,
    output wire [BLOCK_SIZE-1:0] block_out,
    output wire done
);
    // Internal signals
    wire [BLOCK_SIZE-1:0] state_stage1;
    wire valid_stage1;
    
    // Pipeline stage 1: Key mixing submodule
    key_mixer #(
        .BLOCK_SIZE(BLOCK_SIZE)
    ) u_key_mixer (
        .clock(clock),
        .reset_b(reset_b),
        .process(process),
        .block_in(block_in),
        .key(key),
        .mixed_state(state_stage1),
        .state_valid(valid_stage1)
    );

    // Pipeline stage 2-3: Substitution-permutation submodule
    sub_perm_unit #(
        .BLOCK_SIZE(BLOCK_SIZE)
    ) u_sub_perm_unit (
        .clock(clock),
        .reset_b(reset_b),
        .state_valid(valid_stage1),
        .state_in(state_stage1),
        .block_out(block_out),
        .done(done)
    );
endmodule

//-----------------------------------------------------------------------------
// File: key_mixer.v
// Description: Performs key mixing operation (Pipeline stage 1)
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
module key_mixer #(parameter BLOCK_SIZE = 16) (
    input wire clock, reset_b, process,
    input wire [BLOCK_SIZE-1:0] block_in, key,
    output reg [BLOCK_SIZE-1:0] mixed_state,
    output reg state_valid
);
    // Pipeline input registers
    reg process_r;
    reg [BLOCK_SIZE-1:0] block_in_r, key_r;
    
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            process_r <= 1'b0;
            block_in_r <= {BLOCK_SIZE{1'b0}};
            key_r <= {BLOCK_SIZE{1'b0}};
        end else begin
            process_r <= process;
            block_in_r <= block_in;
            key_r <= key;
        end
    end
    
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            mixed_state <= {BLOCK_SIZE{1'b0}};
            state_valid <= 1'b0;
        end else begin
            state_valid <= process_r;
            mixed_state <= process_r ? (block_in_r ^ key_r) : mixed_state;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// File: sub_perm_unit.v
// Description: Performs substitution and permutation operations (Pipeline stages 2-3)
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
module sub_perm_unit #(parameter BLOCK_SIZE = 16) (
    input wire clock, reset_b, state_valid,
    input wire [BLOCK_SIZE-1:0] state_in,
    output reg [BLOCK_SIZE-1:0] block_out,
    output reg done
);
    // Optimized substitution box lookup using ROM-style implementation
    function [3:0] sbox(input [3:0] nibble);
        reg [3:0] result;
        begin
            case(1'b1) // One-hot encoding for better synthesis results
                (nibble == 4'h0): result = 4'hC;
                (nibble == 4'h1): result = 4'h5;
                (nibble == 4'h2): result = 4'h6;
                (nibble == 4'h3): result = 4'hB;
                (nibble == 4'h4): result = 4'h9;
                (nibble == 4'h5): result = 4'h0;
                (nibble == 4'h6): result = 4'hA;
                (nibble == 4'h7): result = 4'hD;
                (nibble == 4'h8): result = 4'h3;
                (nibble == 4'h9): result = 4'hE;
                (nibble == 4'hA): result = 4'hF;
                (nibble == 4'hB): result = 4'h8;
                (nibble == 4'hC): result = 4'h4;
                (nibble == 4'hD): result = 4'h7;
                (nibble == 4'hE): result = 4'h1;
                (nibble == 4'hF): result = 4'h2;
                default: result = 4'h0;
            endcase
            sbox = result;
        end
    endfunction

    // Optimized permutation logic with unrolled loops
    function [BLOCK_SIZE-1:0] permute(input [BLOCK_SIZE-1:0] data);
        reg [BLOCK_SIZE-1:0] result;
        begin
            // Fully unrolled for BLOCK_SIZE=16
            result[3:0]   = data[7:4];
            result[7:4]   = data[11:8];
            result[11:8]  = data[15:12];
            result[15:12] = data[3:0];
            permute = result;
        end
    endfunction

    // Optimized substitution logic with unrolled loops
    function [BLOCK_SIZE-1:0] substitute(input [BLOCK_SIZE-1:0] data);
        reg [BLOCK_SIZE-1:0] result;
        begin
            // Parallel substitution for better timing
            result[3:0]   = sbox(data[3:0]);
            result[7:4]   = sbox(data[7:4]);
            result[11:8]  = sbox(data[11:8]);
            result[15:12] = sbox(data[15:12]);
            substitute = result;
        end
    endfunction

    // Pipeline stage registers
    reg [BLOCK_SIZE-1:0] state_in_r;
    reg state_valid_r;
    reg [BLOCK_SIZE-1:0] permuted_state_r;
    reg valid_stage2_r;

    // Pipeline stage 2: Permutation
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            state_in_r <= {BLOCK_SIZE{1'b0}};
            state_valid_r <= 1'b0;
            permuted_state_r <= {BLOCK_SIZE{1'b0}};
            valid_stage2_r <= 1'b0;
        end else begin
            // Register inputs
            state_in_r <= state_in;
            state_valid_r <= state_valid;
            
            // Permutation stage with optimized comparison
            valid_stage2_r <= state_valid_r;
            if (state_valid_r) begin
                permuted_state_r <= permute(state_in_r);
            end
        end
    end

    // Pipeline stage 3: Substitution
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            block_out <= {BLOCK_SIZE{1'b0}};
            done <= 1'b0;
        end else begin
            // Simplified control logic to reduce comparison chains
            done <= valid_stage2_r;
            if (valid_stage2_r) begin
                block_out <= substitute(permuted_state_r);
            end
        end
    end
endmodule