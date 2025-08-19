//SystemVerilog
//-----------------------------------------------------------------------------
// File: one_hot_load_reg_top.v
// Description: Top-level module for a one-hot load register system
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------

module one_hot_load_reg_top (
    input                  clk,
    input                  rst_n,
    input      [23:0]      data_word,
    input      [2:0]       load_select,  // One-hot encoded
    output     [23:0]      data_out
);

    wire [7:0] byte0_data;
    wire [7:0] byte1_data;
    wire [7:0] byte2_data;
    wire byte0_load, byte1_load, byte2_load;

    // Control unit to decode one-hot select signals
    oh_control_unit u_control (
        .load_select(load_select),
        .byte0_load(byte0_load),
        .byte1_load(byte1_load),
        .byte2_load(byte2_load)
    );

    // Byte register modules
    byte_register #(
        .BYTE_INDEX(0)
    ) u_byte0_reg (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_word[7:0]),
        .load_en(byte0_load),
        .data_out(byte0_data)
    );

    byte_register #(
        .BYTE_INDEX(1)
    ) u_byte1_reg (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_word[15:8]),
        .load_en(byte1_load),
        .data_out(byte1_data)
    );

    byte_register #(
        .BYTE_INDEX(2)
    ) u_byte2_reg (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_word[23:16]),
        .load_en(byte2_load),
        .data_out(byte2_data)
    );

    // Output assembly
    assign data_out = {byte2_data, byte1_data, byte0_data};

endmodule

//-----------------------------------------------------------------------------
// File: oh_control_unit.v
// Description: Control unit to decode one-hot select signals
//-----------------------------------------------------------------------------

module oh_control_unit (
    input      [2:0]       load_select,
    output                 byte0_load,
    output                 byte1_load,
    output                 byte2_load
);

    // Direct mapping of one-hot signals to individual load enables
    assign byte0_load = load_select[0];
    assign byte1_load = load_select[1];
    assign byte2_load = load_select[2];

endmodule

//-----------------------------------------------------------------------------
// File: byte_register.v
// Description: Parametrized byte register with load enable
//-----------------------------------------------------------------------------

module byte_register #(
    parameter BYTE_INDEX = 0
) (
    input                 clk,
    input                 rst_n,
    input      [7:0]      data_in,
    input                 load_en,
    output reg [7:0]      data_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'h0;
        else if (load_en)
            data_out <= data_in;
        // Hold value otherwise
    end

endmodule