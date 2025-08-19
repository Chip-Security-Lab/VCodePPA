//SystemVerilog
// Top-level SPI Slave Async Module (Hierarchical)
module SPI_Slave_Async #(
    parameter ADDR_WIDTH = 3,
    parameter REG_DEPTH = 8
)(
    input wire sck,
    input wire cs_n,
    input wire mosi,
    output wire miso,
    input wire [7:0] reg_file [0:REG_DEPTH-1],
    input wire [ADDR_WIDTH-1:0] addr,
    input wire cpha
);

    // Internal signals
    wire [2:0] bit_counter;
    wire [7:0] serial_shift_data;
    wire sample_edge_pulse;

    // Sample edge generation (CPHA mode support)
    SPI_Slave_EdgeGen u_edge_gen (
        .sck    (sck),
        .cpha   (cpha),
        .sample_edge (sample_edge_pulse)
    );

    // Shift register and bit counter logic
    SPI_Slave_ShiftReg u_shift_reg (
        .clk        (sample_edge_pulse),
        .rst        (cs_n),
        .mosi       (mosi),
        .bit_count  (bit_counter),
        .shift_data (serial_shift_data)
    );

    // MISO output logic
    SPI_Slave_MISO_Out #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .REG_DEPTH  (REG_DEPTH)
    ) u_miso_out (
        .cs_n       (cs_n),
        .reg_file   (reg_file),
        .addr       (addr),
        .bit_count  (bit_counter),
        .miso       (miso)
    );

endmodule

//------------------------------------------------------------------------------
// Edge Generation Module: Determines sample edge based on CPHA mode
//------------------------------------------------------------------------------
module SPI_Slave_EdgeGen (
    input  wire sck,
    input  wire cpha,
    output wire sample_edge
);
    assign sample_edge = (cpha == 1'b0) ? ~sck : sck;
endmodule

//------------------------------------------------------------------------------
// Shift Register and Bit Counter Module
//------------------------------------------------------------------------------
module SPI_Slave_ShiftReg (
    input  wire clk,
    input  wire rst,
    input  wire mosi,
    output reg [2:0] bit_count,
    output reg [7:0] shift_data
);
    wire [2:0] bit_count_next;
    assign bit_count_next = bit_count + (~3'd0 + 3'd1); // 3'd1 is +1, ~3'd0 is all 1's (2's complement of 0 is 0), so this is +1

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            bit_count  <= 3'd0;
            shift_data <= 8'd0;
        end else begin
            shift_data <= {shift_data[6:0], mosi};
            // Use two's complement addition to increment bit_count by 1
            bit_count  <= bit_count + (~3'd0 + 3'd1);
        end
    end
endmodule

//------------------------------------------------------------------------------
// MISO Output Logic Module
//------------------------------------------------------------------------------
module SPI_Slave_MISO_Out #(
    parameter ADDR_WIDTH = 3,
    parameter REG_DEPTH  = 8
)(
    input  wire cs_n,
    input  wire [7:0] reg_file [0:REG_DEPTH-1],
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [2:0] bit_count,
    output reg miso
);
    always @(*) begin
        if(cs_n) begin
            miso = 1'b0;
        end else begin
            miso = reg_file[addr][bit_count];
        end
    end
endmodule