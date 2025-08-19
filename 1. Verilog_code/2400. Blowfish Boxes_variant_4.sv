//SystemVerilog
module blowfish_boxes #(parameter WORD_SIZE = 32, BOX_ENTRIES = 16) (
    input wire clk, rst_n, 
    input wire load_key, encrypt,
    input wire [WORD_SIZE-1:0] data_l, data_r, key_word,
    input wire [3:0] key_idx, s_idx,
    output reg [WORD_SIZE-1:0] out_l, out_r,
    output reg data_valid
);
    // P-box and S-box memory
    reg [WORD_SIZE-1:0] p_box [0:BOX_ENTRIES+1];
    reg [WORD_SIZE-1:0] s_box [0:3][0:BOX_ENTRIES-1];
    
    // Increased pipeline control signals
    reg [3:0] round_stage1, round_stage2, round_stage3, round_stage4, round_stage5, round_stage6;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5, valid_stage6;
    reg encrypt_stage1, encrypt_stage2, encrypt_stage3, encrypt_stage4, encrypt_stage5, encrypt_stage6;
    
    // Pipeline data registers with more stages
    reg [WORD_SIZE-1:0] data_l_stage1, data_r_stage1;
    reg [WORD_SIZE-1:0] data_l_stage2, data_r_stage2;
    reg [WORD_SIZE-1:0] data_l_stage3, data_r_stage3;
    reg [WORD_SIZE-1:0] data_l_stage4, data_r_stage4;
    reg [WORD_SIZE-1:0] data_l_stage5, data_r_stage5;
    reg [WORD_SIZE-1:0] data_l_stage6, data_r_stage6;
    
    // F function intermediate values with increased pipeline depth
    reg [7:0] a_stage1, b_stage1, c_stage1, d_stage1;
    reg [7:0] a_stage2, b_stage2, c_stage2, d_stage2;
    reg [WORD_SIZE-1:0] s_box_a_stage3, s_box_b_stage3;
    reg [WORD_SIZE-1:0] s_box_c_stage3, s_box_d_stage3;
    reg [WORD_SIZE-1:0] s_box_a_stage4, s_box_b_stage4;
    reg [WORD_SIZE-1:0] s_box_c_stage4, s_box_d_stage4;
    reg [WORD_SIZE-1:0] add1_result_stage4;
    reg [WORD_SIZE-1:0] xor_result_stage5;
    reg [WORD_SIZE-1:0] f_result_stage6;
    reg [WORD_SIZE-1:0] p_box_stage5, p_box_stage6;
    
    // Carry lookahead adder signals for first addition
    wire [WORD_SIZE-1:0] cla_sum1;
    wire [WORD_SIZE:0] cla_carry1;
    wire [WORD_SIZE-1:0] p1, g1;
    
    // Carry lookahead adder signals for second addition
    wire [WORD_SIZE-1:0] cla_sum2;
    wire [WORD_SIZE:0] cla_carry2;
    wire [WORD_SIZE-1:0] p2, g2;
    
    // Stage 1: Input and data separation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round_stage1 <= 0;
            valid_stage1 <= 0;
            encrypt_stage1 <= 0;
            data_l_stage1 <= 0;
            data_r_stage1 <= 0;
            a_stage1 <= 0;
            b_stage1 <= 0;
            c_stage1 <= 0;
            d_stage1 <= 0;
            
            // Initialize P-box
            for (integer i = 0; i < BOX_ENTRIES+2; i = i + 1)
                p_box[i] <= i + 1; // Simple initialization
        end else if (load_key) begin
            // Key loading logic - not pipelined
            p_box[key_idx] <= p_box[key_idx] ^ key_word;
            s_box[s_idx[3:2]][s_idx[1:0]] <= s_box[s_idx[3:2]][s_idx[1:0]] ^ {key_word[7:0], key_word[15:8], key_word[23:16], key_word[31:24]};
            valid_stage1 <= 0;
        end else if (encrypt) begin
            encrypt_stage1 <= 1;
            
            if (round_stage1 == 0) begin
                // Initial XOR with P[0]
                data_l_stage1 <= data_l ^ p_box[0];
                data_r_stage1 <= data_r;
                round_stage1 <= 1;
                valid_stage1 <= 1;
            end else if (round_stage1 <= BOX_ENTRIES) begin
                // Split for F function
                a_stage1 <= data_r_stage1[31:24];
                b_stage1 <= data_r_stage1[23:16];
                c_stage1 <= data_r_stage1[15:8];
                d_stage1 <= data_r_stage1[7:0];
                
                data_l_stage1 <= data_r_stage1;
                data_r_stage1 <= data_l_stage1;
                round_stage1 <= round_stage1 + 1;
                valid_stage1 <= 1;
            end else begin
                valid_stage1 <= 0;
                round_stage1 <= 0;
            end
        end else begin
            valid_stage1 <= 0;
            encrypt_stage1 <= 0;
            round_stage1 <= 0;
        end
    end
    
    // Stage 2: Buffer stage for data preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round_stage2 <= 0;
            valid_stage2 <= 0;
            encrypt_stage2 <= 0;
            data_l_stage2 <= 0;
            data_r_stage2 <= 0;
            a_stage2 <= 0;
            b_stage2 <= 0;
            c_stage2 <= 0;
            d_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            encrypt_stage2 <= encrypt_stage1;
            round_stage2 <= round_stage1;
            data_l_stage2 <= data_l_stage1;
            data_r_stage2 <= data_r_stage1;
            
            // Buffer S-box indices
            if (valid_stage1 && encrypt_stage1 && round_stage1 > 1) begin
                a_stage2 <= a_stage1;
                b_stage2 <= b_stage1;
                c_stage2 <= c_stage1;
                d_stage2 <= d_stage1;
            end
        end
    end
    
    // Stage 3: S-box lookups
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round_stage3 <= 0;
            valid_stage3 <= 0;
            encrypt_stage3 <= 0;
            data_l_stage3 <= 0;
            data_r_stage3 <= 0;
            s_box_a_stage3 <= 0;
            s_box_b_stage3 <= 0;
            s_box_c_stage3 <= 0;
            s_box_d_stage3 <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            encrypt_stage3 <= encrypt_stage2;
            round_stage3 <= round_stage2;
            data_l_stage3 <= data_l_stage2;
            data_r_stage3 <= data_r_stage2;
            
            // S-box lookups for F function
            if (valid_stage2 && encrypt_stage2 && round_stage2 > 1) begin
                s_box_a_stage3 <= s_box[0][a_stage2];
                s_box_b_stage3 <= s_box[1][b_stage2];
                s_box_c_stage3 <= s_box[2][c_stage2];
                s_box_d_stage3 <= s_box[3][d_stage2];
            end
        end
    end
    
    // Stage 4: First part of F function calculation (A+B)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round_stage4 <= 0;
            valid_stage4 <= 0;
            encrypt_stage4 <= 0;
            data_l_stage4 <= 0;
            data_r_stage4 <= 0;
            s_box_a_stage4 <= 0;
            s_box_b_stage4 <= 0;
            s_box_c_stage4 <= 0;
            s_box_d_stage4 <= 0;
            add1_result_stage4 <= 0;
        end else begin
            valid_stage4 <= valid_stage3;
            encrypt_stage4 <= encrypt_stage3;
            round_stage4 <= round_stage3;
            data_l_stage4 <= data_l_stage3;
            data_r_stage4 <= data_r_stage3;
            
            if (valid_stage3 && encrypt_stage3 && round_stage3 > 1) begin
                // Save S-box values
                s_box_a_stage4 <= s_box_a_stage3;
                s_box_b_stage4 <= s_box_b_stage3;
                s_box_c_stage4 <= s_box_c_stage3;
                s_box_d_stage4 <= s_box_d_stage3;
                
                // Calculate A+B using carry lookahead adder
                add1_result_stage4 <= cla_sum1;
            end
        end
    end
    
    // Generate propagate and generate signals for first addition
    assign p1 = s_box_a_stage3 | s_box_b_stage3;
    assign g1 = s_box_a_stage3 & s_box_b_stage3;
    
    // Carry lookahead logic for first addition
    assign cla_carry1[0] = 1'b0;  // No initial carry
    generate
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin: carry_gen1
            assign cla_carry1[i+1] = g1[i] | (p1[i] & cla_carry1[i]);
        end
        
        for (i = 8; i < 16; i = i + 1) begin: carry_gen2
            assign cla_carry1[i+1] = g1[i] | (p1[i] & cla_carry1[i]);
        end
        
        for (i = 16; i < 24; i = i + 1) begin: carry_gen3
            assign cla_carry1[i+1] = g1[i] | (p1[i] & cla_carry1[i]);
        end
        
        for (i = 24; i < WORD_SIZE; i = i + 1) begin: carry_gen4
            assign cla_carry1[i+1] = g1[i] | (p1[i] & cla_carry1[i]);
        end
    endgenerate
    
    // Sum for first addition
    assign cla_sum1 = s_box_a_stage3 ^ s_box_b_stage3 ^ cla_carry1[WORD_SIZE-1:0];
    
    // Stage 5: Second part of F function - XOR with s_box_c
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round_stage5 <= 0;
            valid_stage5 <= 0;
            encrypt_stage5 <= 0;
            data_l_stage5 <= 0;
            data_r_stage5 <= 0;
            xor_result_stage5 <= 0;
            s_box_d_stage4 <= 0;
            p_box_stage5 <= 0;
        end else begin
            valid_stage5 <= valid_stage4;
            encrypt_stage5 <= encrypt_stage4;
            round_stage5 <= round_stage4;
            data_l_stage5 <= data_l_stage4;
            data_r_stage5 <= data_r_stage4;
            
            if (valid_stage4 && encrypt_stage4 && round_stage4 > 1) begin
                // XOR the result of A+B with C
                xor_result_stage5 <= add1_result_stage4 ^ s_box_c_stage4;
                s_box_d_stage4 <= s_box_d_stage4;
                
                // Store P-box value for later use
                p_box_stage5 <= p_box[round_stage4-1];
            end
        end
    end
    
    // Generate propagate and generate signals for second addition (after XOR with s_box_c_stage4)
    assign p2 = xor_result_stage5 | s_box_d_stage4;
    assign g2 = xor_result_stage5 & s_box_d_stage4;
    
    // Carry lookahead logic for second addition
    assign cla_carry2[0] = 1'b0;  // No initial carry
    generate
        for (i = 0; i < 8; i = i + 1) begin: carry_gen5
            assign cla_carry2[i+1] = g2[i] | (p2[i] & cla_carry2[i]);
        end
        
        for (i = 8; i < 16; i = i + 1) begin: carry_gen6
            assign cla_carry2[i+1] = g2[i] | (p2[i] & cla_carry2[i]);
        end
        
        for (i = 16; i < 24; i = i + 1) begin: carry_gen7
            assign cla_carry2[i+1] = g2[i] | (p2[i] & cla_carry2[i]);
        end
        
        for (i = 24; i < WORD_SIZE; i = i + 1) begin: carry_gen8
            assign cla_carry2[i+1] = g2[i] | (p2[i] & cla_carry2[i]);
        end
    endgenerate
    
    // Sum for second addition - final result of ((s_box_a + s_box_b) ^ s_box_c) + s_box_d
    assign cla_sum2 = xor_result_stage5 ^ s_box_d_stage4 ^ cla_carry2[WORD_SIZE-1:0];
    
    // Stage 6: Final F function calculation and XOR with P-box
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round_stage6 <= 0;
            valid_stage6 <= 0;
            encrypt_stage6 <= 0;
            data_l_stage6 <= 0;
            data_r_stage6 <= 0;
            f_result_stage6 <= 0;
            p_box_stage6 <= 0;
        end else begin
            valid_stage6 <= valid_stage5;
            encrypt_stage6 <= encrypt_stage5;
            round_stage6 <= round_stage5;
            data_l_stage6 <= data_l_stage5;
            data_r_stage6 <= data_r_stage5;
            p_box_stage6 <= p_box_stage5;
            
            // Final F function calculation
            if (valid_stage5 && encrypt_stage5 && round_stage5 > 1) begin
                f_result_stage6 <= cla_sum2;
            end
        end
    end
    
    // Output stage: Combine results and drive outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_l <= 0;
            out_r <= 0;
            data_valid <= 0;
        end else begin
            if (valid_stage6 && encrypt_stage6) begin
                if (round_stage6 == 1) begin
                    // First round just passes through
                    out_l <= data_l_stage6;
                    out_r <= data_r_stage6;
                    data_valid <= 0;
                end else if (round_stage6 <= BOX_ENTRIES+1) begin
                    // Regular rounds
                    out_l <= data_l_stage6;
                    out_r <= data_r_stage6 ^ f_result_stage6 ^ p_box_stage6;
                    data_valid <= (round_stage6 == BOX_ENTRIES+1);
                end
            end else begin
                data_valid <= 0;
            end
        end
    end
endmodule