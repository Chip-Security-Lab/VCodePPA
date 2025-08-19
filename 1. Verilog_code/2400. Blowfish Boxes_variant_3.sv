//SystemVerilog - IEEE 1364-2005
module blowfish_boxes #(parameter WORD_SIZE = 32, BOX_ENTRIES = 16) (
    input wire clk, rst_n, 
    input wire load_key, encrypt,
    input wire [WORD_SIZE-1:0] data_l, data_r, key_word,
    input wire [3:0] key_idx, s_idx,
    output reg [WORD_SIZE-1:0] out_l, out_r,
    output reg data_valid
);
    reg [WORD_SIZE-1:0] p_box [0:BOX_ENTRIES+1];
    reg [WORD_SIZE-1:0] s_box [0:3][0:BOX_ENTRIES-1];
    reg [3:0] round;
    wire [WORD_SIZE-1:0] f_out;
    
    // Kogge-Stone 8-bit Adder module instantiation
    function [7:0] kogge_stone_add(input [7:0] a, input [7:0] b);
        reg [7:0] p, g; // propagate, generate
        reg [7:0] p_stage1, g_stage1;
        reg [7:0] p_stage2, g_stage2;
        reg [7:0] p_stage3, g_stage3;
        reg [7:0] sum;
        begin
            // Stage 0: Initialize p and g
            p = a ^ b;
            g = a & b;
            
            // Stage 1: Generate group p and g for distance 1
            p_stage1 = p;
            g_stage1 = g;
            
            p_stage1[1] = p[1] & p[0];
            g_stage1[1] = g[1] | (p[1] & g[0]);
            
            p_stage1[2] = p[2] & p[1];
            g_stage1[2] = g[2] | (p[2] & g[1]);
            
            p_stage1[3] = p[3] & p[2];
            g_stage1[3] = g[3] | (p[3] & g[2]);
            
            p_stage1[4] = p[4] & p[3];
            g_stage1[4] = g[4] | (p[4] & g[3]);
            
            p_stage1[5] = p[5] & p[4];
            g_stage1[5] = g[5] | (p[5] & g[4]);
            
            p_stage1[6] = p[6] & p[5];
            g_stage1[6] = g[6] | (p[6] & g[5]);
            
            p_stage1[7] = p[7] & p[6];
            g_stage1[7] = g[7] | (p[7] & g[6]);
            
            // Stage 2: Generate group p and g for distance 2
            p_stage2 = p_stage1;
            g_stage2 = g_stage1;
            
            p_stage2[2] = p_stage1[2] & p_stage1[0];
            g_stage2[2] = g_stage1[2] | (p_stage1[2] & g_stage1[0]);
            
            p_stage2[3] = p_stage1[3] & p_stage1[1];
            g_stage2[3] = g_stage1[3] | (p_stage1[3] & g_stage1[1]);
            
            p_stage2[4] = p_stage1[4] & p_stage1[2];
            g_stage2[4] = g_stage1[4] | (p_stage1[4] & g_stage1[2]);
            
            p_stage2[5] = p_stage1[5] & p_stage1[3];
            g_stage2[5] = g_stage1[5] | (p_stage1[5] & g_stage1[3]);
            
            p_stage2[6] = p_stage1[6] & p_stage1[4];
            g_stage2[6] = g_stage1[6] | (p_stage1[6] & g_stage1[4]);
            
            p_stage2[7] = p_stage1[7] & p_stage1[5];
            g_stage2[7] = g_stage1[7] | (p_stage1[7] & g_stage1[5]);
            
            // Stage 3: Generate group p and g for distance 4
            p_stage3 = p_stage2;
            g_stage3 = g_stage2;
            
            p_stage3[4] = p_stage2[4] & p_stage2[0];
            g_stage3[4] = g_stage2[4] | (p_stage2[4] & g_stage2[0]);
            
            p_stage3[5] = p_stage2[5] & p_stage2[1];
            g_stage3[5] = g_stage2[5] | (p_stage2[5] & g_stage2[1]);
            
            p_stage3[6] = p_stage2[6] & p_stage2[2];
            g_stage3[6] = g_stage2[6] | (p_stage2[6] & g_stage2[2]);
            
            p_stage3[7] = p_stage2[7] & p_stage2[3];
            g_stage3[7] = g_stage2[7] | (p_stage2[7] & g_stage2[3]);
            
            // Compute Sum
            sum[0] = p[0];
            sum[1] = p[1] ^ g_stage1[0];
            sum[2] = p[2] ^ g_stage2[1];
            sum[3] = p[3] ^ g_stage2[2];
            sum[4] = p[4] ^ g_stage3[3];
            sum[5] = p[5] ^ g_stage3[4];
            sum[6] = p[6] ^ g_stage3[5];
            sum[7] = p[7] ^ g_stage3[6];
            
            kogge_stone_add = sum;
        end
    endfunction
    
    // F function with Kogge-Stone adders
    function [WORD_SIZE-1:0] f_function(input [WORD_SIZE-1:0] x);
        reg [7:0] a, b, c, d;
        reg [7:0] sum1, sum2, final_sum;
        reg [WORD_SIZE-1:0] result;
        begin
            a = x[31:24];
            b = x[23:16];
            c = x[15:8];
            d = x[7:0];
            
            // Replace simple additions with Kogge-Stone adders
            sum1 = kogge_stone_add(s_box[0][a][7:0], s_box[1][b][7:0]);
            sum2 = kogge_stone_add(s_box[2][c][7:0] ^ sum1, s_box[3][d][7:0]);
            
            // Handle higher bytes - using Kogge-Stone for each byte
            result[7:0] = sum2;
            result[15:8] = kogge_stone_add(s_box[0][a][15:8], s_box[1][b][15:8]) ^ 
                          kogge_stone_add(s_box[2][c][15:8], s_box[3][d][15:8]);
            result[23:16] = kogge_stone_add(s_box[0][a][23:16], s_box[1][b][23:16]) ^ 
                           kogge_stone_add(s_box[2][c][23:16], s_box[3][d][23:16]);
            result[31:24] = kogge_stone_add(s_box[0][a][31:24], s_box[1][b][31:24]) ^ 
                           kogge_stone_add(s_box[2][c][31:24], s_box[3][d][31:24]);
            
            f_function = result;
        end
    endfunction
    
    assign f_out = f_function(data_r);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round <= 0;
            data_valid <= 0;
            for (integer i = 0; i < BOX_ENTRIES+2; i = i + 1)
                p_box[i] <= i + 1; // Simple initialization
        end else begin
            case ({load_key, encrypt, round})
                // Load key operation
                {1'b1, 1'b0, 4'b????}: begin
                    p_box[key_idx] <= p_box[key_idx] ^ key_word;
                    s_box[s_idx[3:2]][s_idx[1:0]] <= s_box[s_idx[3:2]][s_idx[1:0]] ^ {key_word[7:0], key_word[15:8], key_word[23:16], key_word[31:24]};
                end
                
                // Encryption operations
                {1'b0, 1'b1, 4'b0000}: begin
                    out_l <= data_l ^ p_box[0];
                    out_r <= data_r;
                    round <= 1;
                    data_valid <= 0;
                end
                
                // Mid-rounds of encryption
                {1'b0, 1'b1, 4'b????}: begin
                    if (round <= BOX_ENTRIES) begin
                        out_l <= out_r;
                        out_r <= out_l ^ f_out ^ p_box[round];
                        
                        if (round == BOX_ENTRIES)
                            data_valid <= 1'b1;
                        else
                            data_valid <= 1'b0;
                            
                        round <= round + 1;
                    end
                end
                
                // Reset round counter on no operation
                default: begin
                    if (!encrypt)
                        round <= 0;
                end
            endcase
        end
    end
endmodule