//SystemVerilog
module enc_64b66b (
    input wire clk, rst_n,
    input wire encode,
    input wire [63:0] data_in,
    input wire [1:0] block_type, // 00=data, 01=ctrl, 10=mixed, 11=reserved
    input wire [65:0] encoded_in,
    output reg [65:0] encoded_out,
    output reg [63:0] data_out,
    output reg [1:0] type_out,
    output reg valid_out, err_detected
);
    // Scrambler polynomial: x^58 + x^39 + 1
    reg [57:0] scrambler_state;
    
    // Pipeline registers for stage 1
    reg encode_stage1;
    reg [63:0] data_in_stage1;
    reg [1:0] block_type_stage1;
    reg [65:0] encoded_in_stage1;
    reg valid_stage1;
    
    // Pipeline registers for stage 2
    reg encode_stage2;
    reg [1:0] block_type_stage2;
    reg [63:0] data_in_stage2;
    reg valid_stage2;
    
    // Pipeline registers for stage 3
    reg encode_stage3;
    reg [1:0] block_type_stage3;
    reg [63:0] scrambled_data_stage3;
    reg valid_stage3;
    
    // Pipeline registers for stage 4
    reg encode_stage4;
    reg [1:0] block_type_stage4;
    reg [63:0] scrambled_data_stage4;
    reg valid_stage4;
    
    // Intermediate signals
    reg [63:0] scrambled_data_part1, scrambled_data_part2;
    reg [57:0] next_scrambler_state, scrambler_state_stage2, scrambler_state_stage3;
    reg [31:0] partial_scrambled_stage2;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encode_stage1 <= 1'b0;
            data_in_stage1 <= 64'b0;
            block_type_stage1 <= 2'b0;
            encoded_in_stage1 <= 66'b0;
            valid_stage1 <= 1'b0;
            scrambler_state <= 58'h3_FFFF_FFFF_FFFF;
        end else begin
            encode_stage1 <= encode;
            data_in_stage1 <= data_in;
            block_type_stage1 <= block_type;
            encoded_in_stage1 <= encoded_in;
            valid_stage1 <= encode;
        end
    end
    
    // Stage 2: First part of scrambling computation (32 bits)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encode_stage2 <= 1'b0;
            block_type_stage2 <= 2'b0;
            data_in_stage2 <= 64'b0;
            valid_stage2 <= 1'b0;
            scrambler_state_stage2 <= 58'h0;
            partial_scrambled_stage2 <= 32'b0;
        end else begin
            encode_stage2 <= encode_stage1;
            block_type_stage2 <= block_type_stage1;
            data_in_stage2 <= data_in_stage1;
            valid_stage2 <= valid_stage1;
            
            if (encode_stage1 && valid_stage1) begin
                // Process first 32 bits
                scrambled_data_part1 = data_in_stage1[31:0];
                next_scrambler_state = scrambler_state;
                
                for (int i = 0; i < 32; i = i + 1) begin
                    scrambled_data_part1[i] = data_in_stage1[i] ^ 
                                         next_scrambler_state[57] ^ 
                                         next_scrambler_state[38];
                    next_scrambler_state = {next_scrambler_state[56:0], 
                                       next_scrambler_state[57] ^ next_scrambler_state[38]};
                end
                
                partial_scrambled_stage2 <= scrambled_data_part1[31:0];
                scrambler_state_stage2 <= next_scrambler_state;
            end
        end
    end
    
    // Stage 3: Second part of scrambling computation (remaining 32 bits)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encode_stage3 <= 1'b0;
            block_type_stage3 <= 2'b0;
            scrambled_data_stage3 <= 64'b0;
            valid_stage3 <= 1'b0;
            scrambler_state_stage3 <= 58'h0;
        end else begin
            encode_stage3 <= encode_stage2;
            block_type_stage3 <= block_type_stage2;
            valid_stage3 <= valid_stage2;
            
            if (encode_stage2 && valid_stage2) begin
                // Process remaining 32 bits
                scrambled_data_part2 = data_in_stage2[63:32];
                next_scrambler_state = scrambler_state_stage2;
                
                for (int i = 0; i < 32; i = i + 1) begin
                    scrambled_data_part2[i] = data_in_stage2[i+32] ^ 
                                         next_scrambler_state[57] ^ 
                                         next_scrambler_state[38];
                    next_scrambler_state = {next_scrambler_state[56:0], 
                                       next_scrambler_state[57] ^ next_scrambler_state[38]};
                end
                
                // Combine results from stage 2 and 3
                scrambled_data_stage3 <= {scrambled_data_part2, partial_scrambled_stage2};
                scrambler_state_stage3 <= next_scrambler_state;
            end
        end
    end
    
    // Stage 4: Prepare final output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encode_stage4 <= 1'b0;
            block_type_stage4 <= 2'b0;
            scrambled_data_stage4 <= 64'b0;
            valid_stage4 <= 1'b0;
        end else begin
            encode_stage4 <= encode_stage3;
            block_type_stage4 <= block_type_stage3;
            scrambled_data_stage4 <= scrambled_data_stage3;
            valid_stage4 <= valid_stage3;
            
            if (encode_stage3 && valid_stage3) begin
                scrambler_state <= scrambler_state_stage3;
            end
        end
    end
    
    // Stage 5: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out <= 66'b0;
            data_out <= 64'b0;
            type_out <= 2'b0;
            valid_out <= 1'b0;
            err_detected <= 1'b0;
        end else begin
            if (encode_stage4 && valid_stage4) begin
                // Add sync header (2 bits)
                encoded_out[65:64] <= (block_type_stage4 == 2'b00) ? 2'b01 : 2'b10;
                
                // Output the scrambled payload
                encoded_out[63:0] <= scrambled_data_stage4;
                
                valid_out <= 1'b1;
            end else if (!encode_stage4 && valid_stage4) begin
                // Decoding logic would go here
                // This part would need to be pipelined as well if implemented
                valid_out <= 1'b0;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule