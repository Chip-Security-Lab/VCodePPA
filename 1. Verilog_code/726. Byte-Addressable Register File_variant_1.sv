//SystemVerilog
// Top-level module
module byte_addressable_regfile #(
    parameter WORD_WIDTH = 32,
    parameter ADDR_WIDTH = 8,
    parameter WORD_ADDR_WIDTH = ADDR_WIDTH - 2,
    parameter NUM_WORDS = 2**WORD_ADDR_WIDTH
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     write_en,
    input  wire [ADDR_WIDTH-1:0]    write_byte_addr,
    input  wire [7:0]               write_byte_data,
    input  wire [WORD_ADDR_WIDTH-1:0] read_word_addr,
    output wire [WORD_WIDTH-1:0]      read_word_data
);

    // Address decoder signals
    wire [WORD_ADDR_WIDTH-1:0] write_word_addr;
    wire [1:0] byte_select;
    
    // Memory interface signals
    wire [WORD_WIDTH-1:0] write_word_data;
    wire [WORD_WIDTH-1:0] read_word_data_int;
    
    // Instantiate address decoder
    address_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .WORD_ADDR_WIDTH(WORD_ADDR_WIDTH)
    ) addr_decoder (
        .byte_addr(write_byte_addr),
        .word_addr(write_word_addr),
        .byte_select(byte_select)
    );
    
    // Instantiate byte writer
    byte_writer #(
        .WORD_WIDTH(WORD_WIDTH)
    ) writer (
        .clk(clk),
        .reset(reset),
        .write_en(write_en),
        .byte_select(byte_select),
        .write_byte_data(write_byte_data),
        .write_word_data(write_word_data)
    );
    
    // Instantiate memory array
    memory_array #(
        .WORD_WIDTH(WORD_WIDTH),
        .WORD_ADDR_WIDTH(WORD_ADDR_WIDTH),
        .NUM_WORDS(NUM_WORDS)
    ) mem (
        .clk(clk),
        .reset(reset),
        .write_en(write_en),
        .write_word_addr(write_word_addr),
        .write_word_data(write_word_data),
        .read_word_addr(read_word_addr),
        .read_word_data(read_word_data_int)
    );
    
    assign read_word_data = read_word_data_int;
    
endmodule

// Address decoder module
module address_decoder #(
    parameter ADDR_WIDTH = 8,
    parameter WORD_ADDR_WIDTH = ADDR_WIDTH - 2
)(
    input  wire [ADDR_WIDTH-1:0]    byte_addr,
    output wire [WORD_ADDR_WIDTH-1:0] word_addr,
    output wire [1:0]                byte_select
);
    assign word_addr = byte_addr[ADDR_WIDTH-1:2];
    assign byte_select = byte_addr[1:0];
endmodule

// Byte writer module
module byte_writer #(
    parameter WORD_WIDTH = 32
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     write_en,
    input  wire [1:0]               byte_select,
    input  wire [7:0]               write_byte_data,
    output reg  [WORD_WIDTH-1:0]    write_word_data
);
    reg [7:0] write_byte_data_buf;
    
    always @(posedge clk) begin
        if (reset) begin
            write_word_data <= {WORD_WIDTH{1'b0}};
            write_byte_data_buf <= 8'b0;
        end
        else if (write_en) begin
            write_byte_data_buf <= write_byte_data;
            case (byte_select)
                2'b00: write_word_data[7:0]   <= write_byte_data_buf;
                2'b01: write_word_data[15:8]  <= write_byte_data_buf;
                2'b10: write_word_data[23:16] <= write_byte_data_buf;
                2'b11: write_word_data[31:24] <= write_byte_data_buf;
                default: write_word_data[7:0] <= write_byte_data_buf;
            endcase
        end
    end
endmodule

// Memory array module
module memory_array #(
    parameter WORD_WIDTH = 32,
    parameter WORD_ADDR_WIDTH = 6,
    parameter NUM_WORDS = 2**WORD_ADDR_WIDTH
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     write_en,
    input  wire [WORD_ADDR_WIDTH-1:0] write_word_addr,
    input  wire [WORD_WIDTH-1:0]    write_word_data,
    input  wire [WORD_ADDR_WIDTH-1:0] read_word_addr,
    output wire [WORD_WIDTH-1:0]    read_word_data
);
    reg [WORD_WIDTH-1:0] memory [0:NUM_WORDS-1];
    
    assign read_word_data = memory[read_word_addr];
    
    always @(posedge clk) begin
        if (reset) begin
            integer i;
            for (i = 0; i < NUM_WORDS; i = i + 1) begin
                memory[i] <= {WORD_WIDTH{1'b0}};
            end
        end
        else if (write_en) begin
            memory[write_word_addr] <= write_word_data;
        end
    end
endmodule