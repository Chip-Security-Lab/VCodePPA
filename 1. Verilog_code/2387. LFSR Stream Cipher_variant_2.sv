//SystemVerilog
module lfsr_stream_cipher #(parameter LFSR_WIDTH = 16, DATA_WIDTH = 8) (
    input wire clk, arst_l,
    input wire seed_load, encrypt,
    input wire [LFSR_WIDTH-1:0] seed,
    input wire [DATA_WIDTH-1:0] data_i,
    output reg [DATA_WIDTH-1:0] data_o
);
    reg [LFSR_WIDTH-1:0] lfsr_reg;
    wire feedback;
    
    assign feedback = lfsr_reg[0] ^ lfsr_reg[2] ^ lfsr_reg[3] ^ lfsr_reg[5]; // Tap positions
    
    always @(posedge clk or negedge arst_l) begin
        if (~arst_l) lfsr_reg <= {LFSR_WIDTH{1'b1}};
        else if (seed_load) lfsr_reg <= seed;
        else lfsr_reg <= {feedback, lfsr_reg[LFSR_WIDTH-1:1]};
    end
    
    // 使用条件反相减法器算法实现
    wire [DATA_WIDTH-1:0] key_stream;
    wire [DATA_WIDTH-1:0] result;
    
    assign key_stream = lfsr_reg[LFSR_WIDTH-1:LFSR_WIDTH-DATA_WIDTH];
    
    // 条件反相减法器实现
    wire [DATA_WIDTH:0] cin; // 进位信号
    wire [DATA_WIDTH-1:0] key_stream_inv; // 反相后的key_stream
    
    assign key_stream_inv = ~key_stream;
    assign cin[0] = 1'b1; // 加1的初始进位
    
    // 使用加法器和反相来实现减法 (A-B = A+(-B) = A+(~B+1))
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin: adder_stage
            assign result[i] = data_i[i] ^ key_stream_inv[i] ^ cin[i];
            assign cin[i+1] = (data_i[i] & key_stream_inv[i]) | (data_i[i] & cin[i]) | (key_stream_inv[i] & cin[i]);
        end
    endgenerate
    
    always @(posedge clk or negedge arst_l) begin
        if (~arst_l) data_o <= 0;
        else if (encrypt) data_o <= result;
    end
endmodule