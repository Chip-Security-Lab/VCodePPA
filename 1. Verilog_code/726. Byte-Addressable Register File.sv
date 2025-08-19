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
    
    // Compute word address and byte position within the word
    wire [WORD_ADDR_WIDTH-1:0] write_word_addr = write_byte_addr[ADDR_WIDTH-1:2];
    wire [1:0] byte_select = write_byte_addr[1:0]; // Which byte in the word
    
    // Read entire word
    assign read_word_data = memory[read_word_addr];
    
    // Write a single byte within a word
    always @(posedge clk) begin
        if (reset) begin
            integer i;
            for (i = 0; i < NUM_WORDS; i = i + 1) begin
                memory[i] <= {WORD_WIDTH{1'b0}};
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