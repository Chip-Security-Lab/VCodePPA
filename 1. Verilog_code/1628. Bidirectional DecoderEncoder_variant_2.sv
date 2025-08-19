//SystemVerilog
module bidir_decoder (
    input decode_mode,
    input [2:0] addr_in,
    input [7:0] onehot_in,
    output reg [2:0] addr_out,
    output reg [7:0] onehot_out,
    output reg error
);
    // Parallel prefix adder implementation for 8-bit onehot encoding/decoding
    wire [7:0] prefix_propagate;
    wire [7:0] prefix_generate;
    wire [7:0] prefix_carry;
    wire [7:0] prefix_sum;
    
    // Generate and propagate signals
    assign prefix_propagate[0] = 1'b1;  // Always propagate in onehot encoding
    assign prefix_generate[0] = onehot_in[0];
    assign prefix_propagate[1] = 1'b1;
    assign prefix_generate[1] = onehot_in[1];
    assign prefix_propagate[2] = 1'b1;
    assign prefix_generate[2] = onehot_in[2];
    assign prefix_propagate[3] = 1'b1;
    assign prefix_generate[3] = onehot_in[3];
    assign prefix_propagate[4] = 1'b1;
    assign prefix_generate[4] = onehot_in[4];
    assign prefix_propagate[5] = 1'b1;
    assign prefix_generate[5] = onehot_in[5];
    assign prefix_propagate[6] = 1'b1;
    assign prefix_generate[6] = onehot_in[6];
    assign prefix_propagate[7] = 1'b1;
    assign prefix_generate[7] = onehot_in[7];
    
    // Parallel prefix tree - Brent-Kung structure
    wire [7:0] level1_propagate, level1_generate;
    wire [7:0] level2_propagate, level2_generate;
    wire [7:0] level3_propagate, level3_generate;
    
    // Level 1: 1-bit grouping
    assign level1_propagate[0] = prefix_propagate[0];
    assign level1_generate[0] = prefix_generate[0];
    assign level1_propagate[1] = prefix_propagate[1] & prefix_propagate[0];
    assign level1_generate[1] = prefix_generate[1] | (prefix_propagate[1] & prefix_generate[0]);
    assign level1_propagate[2] = prefix_propagate[2] & prefix_propagate[1];
    assign level1_generate[2] = prefix_generate[2] | (prefix_propagate[2] & prefix_generate[1]);
    assign level1_propagate[3] = prefix_propagate[3] & prefix_propagate[2];
    assign level1_generate[3] = prefix_generate[3] | (prefix_propagate[3] & prefix_generate[2]);
    assign level1_propagate[4] = prefix_propagate[4] & prefix_propagate[3];
    assign level1_generate[4] = prefix_generate[4] | (prefix_propagate[4] & prefix_generate[3]);
    assign level1_propagate[5] = prefix_propagate[5] & prefix_propagate[4];
    assign level1_generate[5] = prefix_generate[5] | (prefix_propagate[5] & prefix_generate[4]);
    assign level1_propagate[6] = prefix_propagate[6] & prefix_propagate[5];
    assign level1_generate[6] = prefix_generate[6] | (prefix_propagate[6] & prefix_generate[5]);
    assign level1_propagate[7] = prefix_propagate[7] & prefix_propagate[6];
    assign level1_generate[7] = prefix_generate[7] | (prefix_propagate[7] & prefix_generate[6]);
    
    // Level 2: 2-bit grouping
    assign level2_propagate[0] = level1_propagate[0];
    assign level2_generate[0] = level1_generate[0];
    assign level2_propagate[1] = level1_propagate[1];
    assign level2_generate[1] = level1_generate[1];
    assign level2_propagate[2] = level1_propagate[2] & level1_propagate[0];
    assign level2_generate[2] = level1_generate[2] | (level1_propagate[2] & level1_generate[0]);
    assign level2_propagate[3] = level1_propagate[3] & level1_propagate[1];
    assign level2_generate[3] = level1_generate[3] | (level1_propagate[3] & level1_generate[1]);
    assign level2_propagate[4] = level1_propagate[4] & level1_propagate[2];
    assign level2_generate[4] = level1_generate[4] | (level1_propagate[4] & level1_generate[2]);
    assign level2_propagate[5] = level1_propagate[5] & level1_propagate[3];
    assign level2_generate[5] = level1_generate[5] | (level1_propagate[5] & level1_generate[3]);
    assign level2_propagate[6] = level1_propagate[6] & level1_propagate[4];
    assign level2_generate[6] = level1_generate[6] | (level1_propagate[6] & level1_generate[4]);
    assign level2_propagate[7] = level1_propagate[7] & level1_propagate[5];
    assign level2_generate[7] = level1_generate[7] | (level1_propagate[7] & level1_generate[5]);
    
    // Level 3: 4-bit grouping
    assign level3_propagate[0] = level2_propagate[0];
    assign level3_generate[0] = level2_generate[0];
    assign level3_propagate[1] = level2_propagate[1];
    assign level3_generate[1] = level2_generate[1];
    assign level3_propagate[2] = level2_propagate[2];
    assign level3_generate[2] = level2_generate[2];
    assign level3_propagate[3] = level2_propagate[3];
    assign level3_generate[3] = level2_generate[3];
    assign level3_propagate[4] = level2_propagate[4] & level2_propagate[0];
    assign level3_generate[4] = level2_generate[4] | (level2_propagate[4] & level2_generate[0]);
    assign level3_propagate[5] = level2_propagate[5] & level2_propagate[1];
    assign level3_generate[5] = level2_generate[5] | (level2_propagate[5] & level2_generate[1]);
    assign level3_propagate[6] = level2_propagate[6] & level2_propagate[2];
    assign level3_generate[6] = level2_generate[6] | (level2_propagate[6] & level2_generate[2]);
    assign level3_propagate[7] = level2_propagate[7] & level2_propagate[3];
    assign level3_generate[7] = level2_generate[7] | (level2_propagate[7] & level2_generate[3]);
    
    // Final carry computation
    assign prefix_carry[0] = 1'b0;
    assign prefix_carry[1] = level3_generate[0] | (level3_propagate[0] & prefix_carry[0]);
    assign prefix_carry[2] = level3_generate[1] | (level3_propagate[1] & prefix_carry[1]);
    assign prefix_carry[3] = level3_generate[2] | (level3_propagate[2] & prefix_carry[2]);
    assign prefix_carry[4] = level3_generate[3] | (level3_propagate[3] & prefix_carry[3]);
    assign prefix_carry[5] = level3_generate[4] | (level3_propagate[4] & prefix_carry[4]);
    assign prefix_carry[6] = level3_generate[5] | (level3_propagate[5] & prefix_carry[5]);
    assign prefix_carry[7] = level3_generate[6] | (level3_propagate[6] & prefix_carry[6]);
    
    // Sum computation
    assign prefix_sum[0] = prefix_propagate[0] ^ prefix_carry[0];
    assign prefix_sum[1] = prefix_propagate[1] ^ prefix_carry[1];
    assign prefix_sum[2] = prefix_propagate[2] ^ prefix_carry[2];
    assign prefix_sum[3] = prefix_propagate[3] ^ prefix_carry[3];
    assign prefix_sum[4] = prefix_propagate[4] ^ prefix_carry[4];
    assign prefix_sum[5] = prefix_propagate[5] ^ prefix_carry[5];
    assign prefix_sum[6] = prefix_propagate[6] ^ prefix_carry[6];
    assign prefix_sum[7] = prefix_propagate[7] ^ prefix_carry[7];
    
    // Main logic
    always @(*) begin
        error = 1'b0;
        addr_out = 3'b000;
        onehot_out = 8'b00000000;
        
        if (decode_mode) begin
            // Decoder mode - use parallel prefix adder result
            onehot_out = (8'b00000001 << addr_in);
        end else begin
            // Encoder mode - use parallel prefix adder for position detection
            error = 1'b1;
            
            if (prefix_sum[0]) begin
                addr_out = 3'b000;
                error = ~(onehot_in == 8'b00000001);
            end
            else if (prefix_sum[1]) begin
                addr_out = 3'b001;
                error = ~(onehot_in == 8'b00000010);
            end
            else if (prefix_sum[2]) begin
                addr_out = 3'b010;
                error = ~(onehot_in == 8'b00000100);
            end
            else if (prefix_sum[3]) begin
                addr_out = 3'b011;
                error = ~(onehot_in == 8'b00001000);
            end
            else if (prefix_sum[4]) begin
                addr_out = 3'b100;
                error = ~(onehot_in == 8'b00010000);
            end
            else if (prefix_sum[5]) begin
                addr_out = 3'b101;
                error = ~(onehot_in == 8'b00100000);
            end
            else if (prefix_sum[6]) begin
                addr_out = 3'b110;
                error = ~(onehot_in == 8'b01000000);
            end
            else if (prefix_sum[7]) begin
                addr_out = 3'b111;
                error = ~(onehot_in == 8'b10000000);
            end
        end
    end
endmodule