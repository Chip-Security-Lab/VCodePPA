//SystemVerilog
// Top-level module
module one_hot_load_reg (
    input               clk,
    input               rst_n,
    input      [23:0]   data_word,
    input      [2:0]    load_select,  // One-hot encoded
    output     [23:0]   data_out
);
    // Register data_word and load_select to improve timing
    reg [23:0] data_word_reg;
    reg [2:0]  load_select_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_word_reg <= 24'h0;
            load_select_reg <= 3'h0;
        end
        else begin
            data_word_reg <= data_word;
            load_select_reg <= load_select;
        end
    end

    // Internal connections
    wire [7:0]  byte0_out;
    wire [7:0]  byte1_out;
    wire [7:0]  byte2_out;
    wire        load_byte0;
    wire        load_byte1;
    wire        load_byte2;

    // Decode load select signals - now using registered input
    load_decoder u_load_decoder (
        .load_select    (load_select_reg),
        .load_byte0     (load_byte0),
        .load_byte1     (load_byte1),
        .load_byte2     (load_byte2)
    );

    // Byte 0 (LSB) handling - now using registered input
    byte_register #(
        .START_BIT      (0)
    ) u_byte0_register (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (data_word_reg[7:0]),
        .load_enable    (load_byte0),
        .byte_out       (byte0_out)
    );

    // Byte 1 (middle) handling - now using registered input
    byte_register #(
        .START_BIT      (8)
    ) u_byte1_register (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (data_word_reg[15:8]),
        .load_enable    (load_byte1),
        .byte_out       (byte1_out)
    );

    // Byte 2 (MSB) handling - now using registered input
    byte_register #(
        .START_BIT      (16)
    ) u_byte2_register (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (data_word_reg[23:16]),
        .load_enable    (load_byte2),
        .byte_out       (byte2_out)
    );

    // Output combiner
    output_combiner u_output_combiner (
        .byte0          (byte0_out),
        .byte1          (byte1_out),
        .byte2          (byte2_out),
        .data_out       (data_out)
    );
endmodule

// Decoder module for load signals
module load_decoder (
    input      [2:0]    load_select,  // One-hot encoded
    output reg          load_byte0,
    output reg          load_byte1,
    output reg          load_byte2
);
    // Decode one-hot load select signals
    always @(*) begin
        load_byte0 = load_select[0];
        load_byte1 = load_select[1];
        load_byte2 = load_select[2];
    end
endmodule

// Parameterized byte register module
module byte_register #(
    parameter START_BIT = 0
)(
    input               clk,
    input               rst_n,
    input      [7:0]    data_in,
    input               load_enable,
    output reg [7:0]    byte_out
);
    // Register implementation for a single byte
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            byte_out <= 8'h0;
        else if (load_enable)
            byte_out <= data_in;
    end
endmodule

// Output combiner module
module output_combiner (
    input      [7:0]    byte0,
    input      [7:0]    byte1,
    input      [7:0]    byte2,
    output     [23:0]   data_out
);
    // Combine the bytes into the final output
    assign data_out = {byte2, byte1, byte0};
endmodule