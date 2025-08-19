//SystemVerilog
// Top-level SPI Slave with hierarchical structure

module SPI_Slave_Async #(
    parameter ADDR_WIDTH = 3,
    parameter REG_DEPTH = 8
)(
    input  wire                   sck,
    input  wire                   cs_n,
    input  wire                   mosi,
    output wire                   miso,
    input  wire [7:0]             reg_file [0:REG_DEPTH-1],
    input  wire [ADDR_WIDTH-1:0]  addr,
    input  wire                   cpha
);

    wire               sample_edge;
    wire [2:0]         bit_counter;
    wire [7:0]         shift_register;
    wire [2:0]         bit_index;
    wire               miso_internal;

    // Sample edge generation submodule
    SPI_Slave_SampleEdge sample_edge_gen (
        .sck       (sck),
        .cpha      (cpha),
        .sample_edge (sample_edge)
    );

    // Shift register and bit counter control submodule
    SPI_Slave_ShiftCtrl shift_ctrl (
        .sample_edge    (sample_edge),
        .cs_n           (cs_n),
        .mosi           (mosi),
        .bit_counter    (bit_counter),
        .shift_register (shift_register)
    );

    // Han-Carlson ALU submodule for subtraction
    SPI_Slave_HanCarlsonALU han_carlson_alu (
        .a              (3'd7),
        .b              (bit_counter),
        .diff           (bit_index)
    );

    // MISO output logic submodule
    SPI_Slave_MISOOut miso_out_unit (
        .cs_n           (cs_n),
        .sample_edge    (sample_edge),
        .reg_file       (reg_file),
        .addr           (addr),
        .bit_index      (bit_index),
        .miso           (miso_internal)
    );

    assign miso = miso_internal;

endmodule

// ------------------------------------------------------
// Sample edge generation module
// Generates the correct sampling edge based on CPHA
// ------------------------------------------------------
module SPI_Slave_SampleEdge(
    input  wire sck,
    input  wire cpha,
    output wire sample_edge
);
    assign sample_edge = (cpha == 1'b0) ? ~sck : sck;
endmodule

// ------------------------------------------------------
// Shift register and bit counter controller
// Handles SPI shifting and bit counting
// ------------------------------------------------------
module SPI_Slave_ShiftCtrl(
    input  wire       sample_edge,
    input  wire       cs_n,
    input  wire       mosi,
    output reg [2:0]  bit_counter,
    output reg [7:0]  shift_register
);
    always @(posedge sample_edge or posedge cs_n) begin
        if (cs_n) begin
            bit_counter   <= 3'd0;
            shift_register <= 8'd0;
        end else begin
            shift_register <= {shift_register[6:0], mosi};
            bit_counter    <= bit_counter + 3'd1;
        end
    end
endmodule

// ------------------------------------------------------
// Han-Carlson ALU module
// Provides 8-bit subtraction via Han-Carlson adder
// ------------------------------------------------------
module SPI_Slave_HanCarlsonALU(
    input  wire [2:0] a,
    input  wire [2:0] b,
    output wire [2:0] diff
);
    wire [7:0] minuend_ext;
    wire [7:0] subtrahend_ext;
    wire [7:0] diff8;

    assign minuend_ext    = {5'b0, a};
    assign subtrahend_ext = {5'b0, b};

    // Han-Carlson subtractor instance
    HanCarlson8_Subtractor sub_inst (
        .minuend    (minuend_ext),
        .subtrahend (subtrahend_ext),
        .diff       (diff8)
    );

    assign diff = diff8[2:0];
endmodule

// ------------------------------------------------------
// MISO output logic
// Computes the correct MISO bit from the register file
// ------------------------------------------------------
module SPI_Slave_MISOOut #(
    parameter ADDR_WIDTH = 3,
    parameter REG_DEPTH  = 8
)(
    input  wire                   cs_n,
    input  wire                   sample_edge,
    input  wire [7:0]             reg_file [0:REG_DEPTH-1],
    input  wire [ADDR_WIDTH-1:0]  addr,
    input  wire [2:0]             bit_index,
    output reg                    miso
);
    always @(posedge sample_edge or posedge cs_n) begin
        if (cs_n) begin
            miso <= 1'b0;
        end else begin
            miso <= reg_file[addr][bit_index];
        end
    end
endmodule

// ------------------------------------------------------
// Han-Carlson 8-bit adder
// ------------------------------------------------------
module HanCarlson8_Adder(
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum
);
    reg [7:0] p, g;
    reg [7:0] gnpg0, gnpg1, gnpg2, gnpg3;
    reg [7:0] carry;
    integer i;

    always @(*) begin
        // Preprocessing
        for (i = 0; i < 8; i = i + 1) begin
            p[i] = a[i] ^ b[i];
            g[i] = a[i] & b[i];
        end

        // Stage 1: Generate and Propagate
        gnpg0[0] = g[0];
        for (i = 1; i < 8; i = i + 1) begin
            gnpg0[i] = g[i] | (p[i] & g[i-1]);
        end

        // Stage 2: 2-distance
        gnpg1[1:0] = gnpg0[1:0];
        for (i = 2; i < 8; i = i + 1) begin
            gnpg1[i] = gnpg0[i] | (p[i] & gnpg0[i-2]);
        end

        // Stage 3: 4-distance
        gnpg2[3:0] = gnpg1[3:0];
        for (i = 4; i < 8; i = i + 1) begin
            gnpg2[i] = gnpg1[i] | (p[i] & gnpg1[i-4]);
        end

        // Stage 4: 8-distance (pipeline placeholder)
        gnpg3 = gnpg2;

        // Carry calculation
        carry[0] = 1'b0;
        carry[1] = gnpg3[0];
        carry[2] = gnpg3[1];
        carry[3] = gnpg3[2];
        carry[4] = gnpg3[3];
        carry[5] = gnpg3[4];
        carry[6] = gnpg3[5];
        carry[7] = gnpg3[6];
    end

    assign sum[0] = p[0] ^ carry[0];
    assign sum[1] = p[1] ^ carry[1];
    assign sum[2] = p[2] ^ carry[2];
    assign sum[3] = p[3] ^ carry[3];
    assign sum[4] = p[4] ^ carry[4];
    assign sum[5] = p[5] ^ carry[5];
    assign sum[6] = p[6] ^ carry[6];
    assign sum[7] = p[7] ^ carry[7];
endmodule

// ------------------------------------------------------
// Han-Carlson 8-bit subtractor (2's complement)
// ------------------------------------------------------
module HanCarlson8_Subtractor(
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output wire [7:0] diff
);
    wire [7:0] subtrahend_complement;
    wire [7:0] one = 8'b1;
    wire [7:0] subtrahend_twos_comp;

    assign subtrahend_complement = ~subtrahend;

    wire [7:0] add_temp;
    HanCarlson8_Adder add1 (
        .a(subtrahend_complement),
        .b(one),
        .sum(add_temp)
    );

    HanCarlson8_Adder add2 (
        .a(minuend),
        .b(add_temp),
        .sum(diff)
    );
endmodule