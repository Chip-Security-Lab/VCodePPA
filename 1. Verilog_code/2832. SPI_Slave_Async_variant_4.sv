//SystemVerilog
// Top-level SPI Slave Async Module
module SPI_Slave_Async #(
    parameter ADDR_WIDTH = 3,
    parameter REG_DEPTH = 8
)(
    input                   sck,
    input                   cs_n,
    input                   mosi,
    output                  miso,
    input  [7:0]            reg_file [0:REG_DEPTH-1],
    input  [ADDR_WIDTH-1:0] addr,
    input                   cpha
);

    // Internal signals
    wire             sample_edge;
    wire [2:0]       bit_counter;
    wire [7:0]       shift_register;
    wire             miso_internal;

    // Edge detector for SPI clock
    SPI_Clock_Edge_Detector edge_detector_inst (
        .sck         (sck),
        .cpha        (cpha),
        .sample_edge (sample_edge)
    );

    // SPI Shift Register and Counter Logic
    SPI_Shift_Logic #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .REG_DEPTH   (REG_DEPTH)
    ) shift_logic_inst (
        .sample_edge (sample_edge),
        .cs_n        (cs_n),
        .mosi        (mosi),
        .reg_file    (reg_file),
        .addr        (addr),
        .bit_cnt     (bit_counter),
        .shift_reg   (shift_register),
        .miso        (miso_internal)
    );

    // Output buffer for MISO
    assign miso = miso_internal;

endmodule

// -----------------------------------------------------------------------------
// SPI_Clock_Edge_Detector
// Detects the SPI clock sampling edge based on CPHA mode
// -----------------------------------------------------------------------------
module SPI_Clock_Edge_Detector(
    input  wire sck,
    input  wire cpha,
    output wire sample_edge
);
    reg sample_edge_reg;
    always @(*) begin
        if (cpha == 1'b0) begin
            sample_edge_reg = ~sck;
        end else begin
            sample_edge_reg = sck;
        end
    end
    assign sample_edge = sample_edge_reg;
endmodule

// -----------------------------------------------------------------------------
// SPI_Shift_Logic
// Handles bit counter, shift register, and MISO output logic
// -----------------------------------------------------------------------------
module SPI_Shift_Logic #(
    parameter ADDR_WIDTH = 3,
    parameter REG_DEPTH  = 8
)(
    input                   sample_edge,
    input                   cs_n,
    input                   mosi,
    input  [7:0]            reg_file [0:REG_DEPTH-1],
    input  [ADDR_WIDTH-1:0] addr,
    output reg  [2:0]       bit_cnt,
    output reg  [7:0]       shift_reg,
    output reg              miso
);
    // SPI shift register and bit count control
    always @(posedge sample_edge or posedge cs_n) begin
        if(cs_n) begin
            bit_cnt   <= 3'b000;
            shift_reg <= 8'b0;
            miso      <= 1'b0;
        end else begin
            shift_reg <= {shift_reg[6:0], mosi};
            if (bit_cnt < 3'd8) begin
                miso <= reg_file[addr][bit_cnt];
            end else begin
                miso <= 1'b0;
            end
            bit_cnt   <= bit_cnt + 1'b1;
        end
    end
endmodule