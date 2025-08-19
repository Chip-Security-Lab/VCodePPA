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
    
    // F function (simplified)
    function [WORD_SIZE-1:0] f_function(input [WORD_SIZE-1:0] x);
        reg [7:0] a, b, c, d;
        reg [WORD_SIZE-1:0] result;
        begin
            a = x[31:24];
            b = x[23:16];
            c = x[15:8];
            d = x[7:0];
            result = ((s_box[0][a] + s_box[1][b]) ^ s_box[2][c]) + s_box[3][d];
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
        end else if (load_key) begin
            p_box[key_idx] <= p_box[key_idx] ^ key_word;
            s_box[s_idx[3:2]][s_idx[1:0]] <= s_box[s_idx[3:2]][s_idx[1:0]] ^ {key_word[7:0], key_word[15:8], key_word[23:16], key_word[31:24]};
        end else if (encrypt) begin
            if (round == 0) begin
                out_l <= data_l ^ p_box[0];
                out_r <= data_r;
                round <= 1;
                data_valid <= 0;
            end else if (round <= BOX_ENTRIES) begin
                out_l <= out_r;
                out_r <= out_l ^ f_out ^ p_box[round];
                round <= round + 1;
                data_valid <= (round == BOX_ENTRIES);
            end
        end else round <= 0;
    end
endmodule