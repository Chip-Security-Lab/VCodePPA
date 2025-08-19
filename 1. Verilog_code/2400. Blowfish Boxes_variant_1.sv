//SystemVerilog
module blowfish_boxes #(parameter WORD_SIZE = 32, BOX_ENTRIES = 16) (
    input wire clk, rst_n, 
    input wire load_key, encrypt,
    input wire [WORD_SIZE-1:0] data_l, data_r, key_word,
    input wire [3:0] key_idx, s_idx,
    output reg [WORD_SIZE-1:0] out_l, out_r,
    output reg data_valid
);
    // P-box memory with registered outputs for improved fanout handling
    reg [WORD_SIZE-1:0] p_box [0:BOX_ENTRIES+1];
    
    // S-box memory with registered outputs
    reg [WORD_SIZE-1:0] s_box [0:3][0:BOX_ENTRIES-1];
    
    // 前置缓存输入信号以减少扇出
    reg [WORD_SIZE-1:0] data_l_buf, data_r_buf;
    reg [WORD_SIZE-1:0] key_word_buf;
    reg [3:0] key_idx_buf, s_idx_buf;
    reg load_key_buf, encrypt_buf;
    
    // 抽取data_r的各字节组件用于f函数
    wire [7:0] a, b, c, d;
    assign a = data_r[31:24];
    assign b = data_r[23:16];
    assign c = data_r[15:8];
    assign d = data_r[7:0];
    
    // 预读取S-box值以准备f函数计算
    reg [WORD_SIZE-1:0] s_box_buf_0, s_box_buf_1, s_box_buf_2, s_box_buf_3;
    reg [WORD_SIZE-1:0] f_out;
    
    // Round counter
    reg [3:0] round;
    
    // P-box buffer registers (按需访问)
    reg [WORD_SIZE-1:0] p_box_out;
    reg [WORD_SIZE-1:0] p_round_out;
    
    // 循环变量
    integer i;
    
    // 第一阶段：缓存输入信号并预取值
    always @(posedge clk) begin
        // 输入缓存
        data_l_buf <= data_l;
        data_r_buf <= data_r;
        key_word_buf <= key_word;
        key_idx_buf <= key_idx;
        s_idx_buf <= s_idx;
        load_key_buf <= load_key;
        encrypt_buf <= encrypt;
        
        // 预读取P-box值
        p_box_out <= p_box[0];
        p_round_out <= p_box[round];
        
        // 预读取S-box值
        s_box_buf_0 <= s_box[0][a];
        s_box_buf_1 <= s_box[1][b];
        s_box_buf_2 <= s_box[2][c];
        s_box_buf_3 <= s_box[3][d];
    end
    
    // 第二阶段：计算f函数结果
    always @(posedge clk) begin
        f_out <= ((s_box_buf_0 + s_box_buf_1) ^ s_box_buf_2) + s_box_buf_3;
    end
    
    // 主状态和控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            round <= 0;
            data_valid <= 0;
            // 初始化 - 将for循环转换为while循环
            i = 0;
            while (i < BOX_ENTRIES+2) begin
                p_box[i] <= i + 1; // Simple initialization
                i = i + 1;
            end
        end else if (load_key_buf) begin
            p_box[key_idx_buf] <= p_box[key_idx_buf] ^ key_word_buf;
            s_box[s_idx_buf[3:2]][s_idx_buf[1:0]] <= s_box[s_idx_buf[3:2]][s_idx_buf[1:0]] ^ 
                                                  {key_word_buf[7:0], key_word_buf[15:8], 
                                                   key_word_buf[23:16], key_word_buf[31:24]};
        end else if (encrypt_buf) begin
            if (round == 0) begin
                out_l <= data_l_buf ^ p_box_out;
                out_r <= data_r_buf;
                round <= 1;
                data_valid <= 0;
            end else if (round <= BOX_ENTRIES) begin
                out_l <= out_r;
                out_r <= out_l ^ f_out ^ p_round_out;
                round <= round + 1;
                data_valid <= (round == BOX_ENTRIES);
            end
        end else round <= 0;
    end
endmodule