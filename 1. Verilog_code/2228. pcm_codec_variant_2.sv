//SystemVerilog
module pcm_codec #(parameter DATA_WIDTH = 16)
(
    input wire clk, rst_n, 
    input wire [DATA_WIDTH-1:0] pcm_in,     // PCM input samples
    input wire [7:0] compressed_in,         // Compressed input
    input wire encode_mode,                 // 1=encode, 0=decode
    output reg [7:0] compressed_out,        // Compressed output
    output reg [DATA_WIDTH-1:0] pcm_out,    // PCM output samples
    output reg data_valid
);
    // μ-law compression constants
    localparam BIAS = 33;
    localparam SEG_SHIFT = 4;
    
    // 寄存器前移 - 将数据捕获寄存器移到输入处
    reg [DATA_WIDTH-1:0] pcm_in_reg;
    reg [7:0] compressed_in_reg;
    reg encode_mode_reg;
    
    // 中间计算结果寄存器
    reg [DATA_WIDTH-1:0] abs_sample;
    reg [3:0] segment;
    reg sign;
    
    // 输入数据寄存化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pcm_in_reg <= {DATA_WIDTH{1'b0}};
            compressed_in_reg <= 8'h00;
            encode_mode_reg <= 1'b0;
        end else begin
            pcm_in_reg <= pcm_in;
            compressed_in_reg <= compressed_in;
            encode_mode_reg <= encode_mode;
        end
    end
    
    // 计算逻辑与输出 - 使用case语句替代if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compressed_out <= 8'h00;
            pcm_out <= {DATA_WIDTH{1'b0}};
            data_valid <= 1'b0;
            abs_sample <= {DATA_WIDTH{1'b0}};
            segment <= 4'b0000;
            sign <= 1'b0;
        end else begin
            // 使用encode_mode_reg作为case语句的控制变量
            case (encode_mode_reg)
                1'b1: begin  // 编码模式
                    // μ-law encoding algorithm
                    sign <= pcm_in_reg[DATA_WIDTH-1];
                    abs_sample <= pcm_in_reg[DATA_WIDTH-1] ? (~pcm_in_reg + 1'b1) : pcm_in_reg;
                    // Determine segment and encode
                    data_valid <= 1'b1;
                end
                
                1'b0: begin  // 解码模式
                    // μ-law decoding algorithm
                    data_valid <= 1'b1;
                end
                
                default: begin  // 安全状态
                    compressed_out <= 8'h00;
                    pcm_out <= {DATA_WIDTH{1'b0}};
                    data_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule