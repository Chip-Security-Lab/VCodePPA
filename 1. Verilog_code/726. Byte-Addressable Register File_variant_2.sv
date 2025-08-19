//SystemVerilog
module byte_addressable_regfile_pipeline #(
    parameter WORD_WIDTH = 32,
    parameter ADDR_WIDTH = 8,    
    parameter WORD_ADDR_WIDTH = ADDR_WIDTH - 2, 
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
    wire [1:0] byte_select = write_byte_addr[1:0];

    // Pipeline registers
    reg [WORD_ADDR_WIDTH-1:0] write_word_addr_stage1, write_word_addr_stage2;
    reg [1:0] byte_select_stage1, byte_select_stage2;
    reg [7:0] write_byte_data_stage1, write_byte_data_stage2;
    reg write_en_stage1, write_en_stage2;

    // Valid signals for pipeline stages
    reg valid_stage1, valid_stage2;

    // Read entire word
    assign read_word_data = memory[read_word_addr];

    // Pipeline control logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            integer i;
            for (i = 0; i < NUM_WORDS; i = i + 1) begin
                memory[i] <= {WORD_WIDTH{1'b0}};
            end
            valid_stage1 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            // Stage 1
            write_word_addr_stage1 <= write_word_addr;
            byte_select_stage1 <= byte_select;
            write_byte_data_stage1 <= write_byte_data;
            write_en_stage1 <= write_en;
            valid_stage1 <= write_en;

            // Stage 2
            write_word_addr_stage2 <= write_word_addr_stage1;
            byte_select_stage2 <= byte_select_stage1;
            write_byte_data_stage2 <= write_byte_data_stage1;
            write_en_stage2 <= valid_stage1;
            valid_stage2 <= valid_stage1;

            // Write a single byte within a word
            if (valid_stage2) begin
                case (byte_select_stage2)
                    2'b00: memory[write_word_addr_stage2][7:0]   <= write_byte_data_stage2;
                    2'b01: memory[write_word_addr_stage2][15:8]  <= write_byte_data_stage2;
                    2'b10: memory[write_word_addr_stage2][23:16] <= write_byte_data_stage2;
                    2'b11: memory[write_word_addr_stage2][31:24] <= write_byte_data_stage2;
                    default: memory[write_word_addr_stage2][7:0] <= write_byte_data_stage2;
                endcase
            end
        end
    end
endmodule