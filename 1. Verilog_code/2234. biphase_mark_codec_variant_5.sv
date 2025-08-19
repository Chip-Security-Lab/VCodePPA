//SystemVerilog
module biphase_mark_codec (
    input wire clk, rst,
    input wire encode, decode,
    input wire data_in,
    input wire biphase_in,
    output reg biphase_out,
    output reg data_out,
    output reg data_valid
);
    // Pipeline stage control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 1: Input registration and timer management
    reg data_in_stage1;
    reg encode_stage1, decode_stage1;
    reg [1:0] bit_timer_stage1;
    wire [1:0] bit_timer_next;
    
    // Stage 2: Transition calculation
    reg data_in_stage2;
    reg encode_stage2;
    reg [1:0] bit_timer_stage2;
    reg transition_needed_stage2;
    
    // Stage 3: Output generation
    reg biphase_value_stage3;
    
    // Han-Carlson adder for 2-bit addition
    han_carlson_adder hca_inst (
        .a(bit_timer_stage1),
        .b(2'b01),
        .sum(bit_timer_next)
    );
    
    // Stage 1: Input registration and timer management
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_in_stage1 <= 1'b0;
            encode_stage1 <= 1'b0;
            decode_stage1 <= 1'b0;
            bit_timer_stage1 <= 2'b00;
            valid_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            encode_stage1 <= encode;
            decode_stage1 <= decode;
            
            if (encode) begin
                bit_timer_stage1 <= bit_timer_next;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Transition calculation
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_in_stage2 <= 1'b0;
            encode_stage2 <= 1'b0;
            bit_timer_stage2 <= 2'b00;
            transition_needed_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            encode_stage2 <= encode_stage1;
            bit_timer_stage2 <= bit_timer_stage1;
            valid_stage2 <= valid_stage1;
            
            // Determine if a transition is needed
            if (valid_stage1) begin
                if (bit_timer_stage1 == 2'b00) 
                    // Start of bit time - always transition
                    transition_needed_stage2 <= 1'b1;
                else if (bit_timer_stage1 == 2'b10 && data_in_stage1)
                    // Mid-bit & data is '1' - additional transition
                    transition_needed_stage2 <= 1'b1;
                else
                    transition_needed_stage2 <= 1'b0;
            end else begin
                transition_needed_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            biphase_out <= 1'b0;
            biphase_value_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            
            if (valid_stage2 && transition_needed_stage2) begin
                biphase_value_stage3 <= ~biphase_value_stage3;
                biphase_out <= ~biphase_value_stage3;
            end else begin
                biphase_out <= biphase_value_stage3;
            end
        end
    end
    
    // Data valid flag based on pipeline stages
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_valid <= 1'b0;
        end else begin
            data_valid <= valid_stage3;
        end
    end
    
    // Decode logic placeholder - would be implemented with similar pipeline stages
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_out <= 1'b0;
        end else begin
            // Placeholder for decode logic (would be pipelined)
            data_out <= 1'b0;
        end
    end
endmodule

module han_carlson_adder (
    input [1:0] a,
    input [1:0] b,
    output [1:0] sum
);
    wire [1:0] p, g; // Propagate and Generate signals
    wire c_mid;      // Internal carry

    // Step 1: Generate propagate and generate signals
    assign p = a ^ b;  // Propagate = a XOR b
    assign g = a & b;  // Generate = a AND b

    // Step 2: For 2-bit Han-Carlson, compute carry
    assign c_mid = g[0];  // Carry into bit 1 is just generate from bit 0
    
    // Step 3: Compute sum
    assign sum[0] = p[0];              // Bit 0 sum (no carry-in)
    assign sum[1] = p[1] ^ c_mid;      // Bit 1 sum with carry-in
endmodule