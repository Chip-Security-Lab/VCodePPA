//SystemVerilog
module blowfish_boxes #(parameter WORD_SIZE = 32, BOX_ENTRIES = 16) (
    input wire clk, rst_n, 
    input wire load_key, encrypt,
    input wire [WORD_SIZE-1:0] data_l, data_r, key_word,
    input wire [3:0] key_idx, s_idx,
    output reg [WORD_SIZE-1:0] out_l, out_r,
    output reg data_valid
);
    // Storage elements
    reg [WORD_SIZE-1:0] p_box [0:BOX_ENTRIES+1];
    reg [WORD_SIZE-1:0] s_box [0:3][0:BOX_ENTRIES-1];
    
    // Pipeline control
    reg [3:0] round_stage1, round_stage2, round_stage3;
    
    // Pipeline registers
    reg [WORD_SIZE-1:0] data_l_stage1, data_r_stage1;
    reg [WORD_SIZE-1:0] data_l_stage2, data_r_stage2;
    reg [WORD_SIZE-1:0] data_l_stage3, data_r_stage3;
    
    // F-function pipeline registers
    reg [7:0] a_stage1, b_stage1, c_stage1, d_stage1;
    reg [WORD_SIZE-1:0] s_box_a_stage2, s_box_b_stage2;
    reg [WORD_SIZE-1:0] s_box_c_stage2, s_box_d_stage2;
    reg [WORD_SIZE-1:0] f_temp1_stage3, f_temp2_stage3, f_out_stage3;
    
    // Pipeline control signals
    reg encrypt_stage1, encrypt_stage2, encrypt_stage3;
    reg round_active_stage1, round_active_stage2, round_active_stage3;
    
    // 条件反相减法器信号 - 用于f_temp1_stage3和f_out_stage3计算
    reg [WORD_SIZE-1:0] sub1_a, sub1_b, sub1_result;
    reg sub1_cin;
    reg [WORD_SIZE-1:0] sub2_a, sub2_b, sub2_result;
    reg sub2_cin;
    
    // F-function decomposed into pipeline stages
    // Stage 1: Extract bytes
    always @(posedge clk) begin
        if (encrypt) begin
            a_stage1 <= data_r[31:24];
            b_stage1 <= data_r[23:16];
            c_stage1 <= data_r[15:8];
            d_stage1 <= data_r[7:0];
        end
    end
    
    // Stage 2: S-box lookups
    always @(posedge clk) begin
        s_box_a_stage2 <= s_box[0][a_stage1];
        s_box_b_stage2 <= s_box[1][b_stage1];
        s_box_c_stage2 <= s_box[2][c_stage1];
        s_box_d_stage2 <= s_box[3][d_stage1];
    end
    
    // 条件反相减法器1实现 (用于s_box_a_stage2 + s_box_b_stage2)
    always @(*) begin
        // 当s_box_a_stage2为负数时，执行条件反相减法
        if (s_box_a_stage2[WORD_SIZE-1]) begin
            sub1_a = ~s_box_a_stage2;
            sub1_b = s_box_b_stage2;
            sub1_cin = 1'b0;
            f_temp1_stage3 = sub1_b - sub1_a - sub1_cin;
        end
        // 当s_box_b_stage2为负数时，执行条件反相减法
        else if (s_box_b_stage2[WORD_SIZE-1]) begin
            sub1_a = s_box_a_stage2;
            sub1_b = ~s_box_b_stage2;
            sub1_cin = 1'b0;
            f_temp1_stage3 = sub1_a - sub1_b - sub1_cin;
        end
        // 两个都是正数，正常相加
        else begin
            f_temp1_stage3 = s_box_a_stage2 + s_box_b_stage2;
        end
    end
    
    // Stage 3: 计算临时结果
    always @(posedge clk) begin
        f_temp2_stage3 <= f_temp1_stage3 ^ s_box_c_stage2;
    end
    
    // 条件反相减法器2实现 (用于f_temp2_stage3 + s_box_d_stage2)
    always @(*) begin
        // 当f_temp2_stage3为负数时，执行条件反相减法
        if (f_temp2_stage3[WORD_SIZE-1]) begin
            sub2_a = ~f_temp2_stage3;
            sub2_b = s_box_d_stage2;
            sub2_cin = 1'b0;
            f_out_stage3 = sub2_b - sub2_a - sub2_cin;
        end
        // 当s_box_d_stage2为负数时，执行条件反相减法
        else if (s_box_d_stage2[WORD_SIZE-1]) begin
            sub2_a = f_temp2_stage3;
            sub2_b = ~s_box_d_stage2;
            sub2_cin = 1'b0;
            f_out_stage3 = sub2_a - sub2_b - sub2_cin;
        end
        // 两个都是正数，正常相加
        else begin
            f_out_stage3 = f_temp2_stage3 + s_box_d_stage2;
        end
    end
    
    // Main pipeline control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers and control signals
            round_stage1 <= 0;
            round_stage2 <= 0;
            round_stage3 <= 0;
            
            encrypt_stage1 <= 0;
            encrypt_stage2 <= 0;
            encrypt_stage3 <= 0;
            
            round_active_stage1 <= 0;
            round_active_stage2 <= 0;
            round_active_stage3 <= 0;
            
            data_valid <= 0;
            
            // Initialize boxes
            for (integer i = 0; i < BOX_ENTRIES+2; i = i + 1)
                p_box[i] <= i + 1; // Simple initialization
        end else begin
            // Pipeline Stage Shifts
            encrypt_stage1 <= encrypt;
            encrypt_stage2 <= encrypt_stage1;
            encrypt_stage3 <= encrypt_stage2;
            
            // Data movement through pipeline
            if (encrypt) begin
                // First stage - input registration
                data_l_stage1 <= data_l;
                data_r_stage1 <= data_r;
                round_stage1 <= (round_active_stage3) ? round_stage3 + 1 : 0;
                round_active_stage1 <= 1;
            end
            
            // Move data through pipeline stages
            data_l_stage2 <= data_l_stage1;
            data_r_stage2 <= data_r_stage1;
            round_stage2 <= round_stage1;
            round_active_stage2 <= round_active_stage1;
            
            data_l_stage3 <= data_l_stage2;
            data_r_stage3 <= data_r_stage2;
            round_stage3 <= round_stage2;
            round_active_stage3 <= round_active_stage2;
            
            // Process key loading separately (not pipelined)
            if (load_key) begin
                p_box[key_idx] <= p_box[key_idx] ^ key_word;
                s_box[s_idx[3:2]][s_idx[1:0]] <= s_box[s_idx[3:2]][s_idx[1:0]] ^ {key_word[7:0], key_word[15:8], key_word[23:16], key_word[31:24]};
            end 
            // Final output stage processing
            else if (round_active_stage3) begin
                if (round_stage3 == 0) begin
                    out_l <= data_l_stage3 ^ p_box[0];
                    out_r <= data_r_stage3;
                    data_valid <= 0;
                end else if (round_stage3 <= BOX_ENTRIES) begin
                    out_l <= data_r_stage3;
                    out_r <= data_l_stage3 ^ f_out_stage3 ^ p_box[round_stage3];
                    data_valid <= (round_stage3 == BOX_ENTRIES);
                end
                
                // Reset pipeline if done
                if (round_stage3 == BOX_ENTRIES) begin
                    round_active_stage3 <= 0;
                end
            end else if (!encrypt && !encrypt_stage1 && !encrypt_stage2) begin
                // Reset round when encrypt is deasserted and has propagated through pipeline
                round_stage1 <= 0;
                round_stage2 <= 0;
                round_stage3 <= 0;
                round_active_stage1 <= 0;
                round_active_stage2 <= 0;
                round_active_stage3 <= 0;
            end
        end
    end
endmodule