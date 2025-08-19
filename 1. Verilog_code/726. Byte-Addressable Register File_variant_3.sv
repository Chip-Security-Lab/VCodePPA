//SystemVerilog
module byte_addressable_regfile #(
    parameter WORD_WIDTH = 32,
    parameter ADDR_WIDTH = 8,    // Byte address width
    parameter WORD_ADDR_WIDTH = ADDR_WIDTH - 2, // Word addressing (assuming 4 bytes per word)
    parameter NUM_WORDS = 2**WORD_ADDR_WIDTH
)(
    input  wire                     clk,
    input  wire                     reset,
    
    // Write interface (byte addressable)
    input  wire                     write_en,
    input  wire [ADDR_WIDTH-1:0]    write_byte_addr,
    input  wire [7:0]               write_byte_data,
    
    // Read interface (word addressable)
    input  wire [WORD_ADDR_WIDTH-1:0] read_word_addr,
    output wire [WORD_WIDTH-1:0]      read_word_data
);
    // Memory array stores complete words
    reg [WORD_WIDTH-1:0] memory [0:NUM_WORDS-1];
    
    // 使用条件反相减法器算法计算地址
    wire [7:0] minuend = write_byte_addr;
    wire [7:0] subtrahend = 8'b00000000;  // 对于字节偏移，我们提取低2位，所以不执行实际减法
    wire [7:0] difference;
    wire borrow_out;
    
    // 条件反相减法器实现
    assign {borrow_out, difference} = minuend + (~subtrahend + 1'b1); // 反相加法

    // 从结果中提取地址和偏移
    wire [WORD_ADDR_WIDTH-1:0] write_word_addr = difference[ADDR_WIDTH-1:2];
    wire [1:0] byte_select = difference[1:0]; // 哪个字节在字内
    
    // 读取整个字
    assign read_word_data = memory[read_word_addr];
    
    // 在字内写入单个字节
    always @(posedge clk) begin
        if (reset) begin
            integer j;
            for (j = 0; j < NUM_WORDS; j = j + 1) begin
                memory[j] <= {WORD_WIDTH{1'b0}};
            end
        end
        else if (write_en) begin
            case (byte_select)
                2'b00: memory[write_word_addr][7:0]   <= write_byte_data;
                2'b01: memory[write_word_addr][15:8]  <= write_byte_data;
                2'b10: memory[write_word_addr][23:16] <= write_byte_data;
                2'b11: memory[write_word_addr][31:24] <= write_byte_data;
                default: memory[write_word_addr][7:0] <= write_byte_data;
            endcase
        end
    end
endmodule