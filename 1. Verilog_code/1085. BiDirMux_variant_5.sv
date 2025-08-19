//SystemVerilog
// Top-level module for 2-bit ALU with hierarchical structure
module TopALU2bit (
    input  [1:0] operand_a,
    input  [1:0] operand_b,
    input        op_sub, // 1: sub, 0: add
    output [1:0] result
);
    // Internal signals
    wire [1:0] alu_operand_b_mux;
    wire       alu_carry_in;
    wire [2:0] alu_sum_ext;

    // Operand B Mux and Inverter: Handles operand_b inversion for subtraction
    OperandBMuxInv u_operand_b_mux_inv (
        .operand_b      (operand_b),
        .op_sub         (op_sub),
        .operand_b_mux  (alu_operand_b_mux)
    );

    // Carry In Generator: Generates carry_in for add/sub operations
    CarryInGen u_carry_in_gen (
        .op_sub         (op_sub),
        .carry_in       (alu_carry_in)
    );

    // 2-bit Adder: Performs addition/subtraction
    Adder2bit u_adder_2bit (
        .operand_a      (operand_a),
        .operand_b      (alu_operand_b_mux),
        .carry_in       (alu_carry_in),
        .sum_ext        (alu_sum_ext)
    );

    // Output selection
    assign result = alu_sum_ext[1:0];

endmodule

//------------------------------------------------------------------------------
// Operand B Mux and Inverter
// Selects and inverts operand_b if subtraction is selected
//------------------------------------------------------------------------------
module OperandBMuxInv (
    input  [1:0] operand_b,
    input        op_sub,
    output [1:0] operand_b_mux
);
    assign operand_b_mux = op_sub ? ~operand_b : operand_b;
endmodule

//------------------------------------------------------------------------------
// Carry In Generator
// Provides the correct carry_in for addition/subtraction
//------------------------------------------------------------------------------
module CarryInGen (
    input  op_sub,
    output carry_in
);
    assign carry_in = op_sub ? 1'b1 : 1'b0;
endmodule

//------------------------------------------------------------------------------
// 2-bit Adder with Carry In
// Performs operand_a + operand_b + carry_in
//------------------------------------------------------------------------------
module Adder2bit (
    input  [1:0] operand_a,
    input  [1:0] operand_b,
    input        carry_in,
    output [2:0] sum_ext
);
    assign sum_ext = {1'b0, operand_a} + {1'b0, operand_b} + carry_in;
endmodule

//------------------------------------------------------------------------------
// Top-level module for BiDirMux with hierarchical structure
//------------------------------------------------------------------------------
module BiDirMux #(parameter DW=8) (
    inout  [DW-1:0] bus,
    input  [(4*DW)-1:0] tx,
    output [(4*DW)-1:0] rx,
    input  [1:0] sel,
    input  oe
);
    // Internal signals
    wire [DW-1:0] bus_data;
    wire [DW-1:0] bus_drive;
    wire [4*DW-1:0] rx_internal;

    // RX Demultiplexer: Distributes bus data to the appropriate RX channel
    RXDemux #(.DW(DW)) u_rx_demux (
        .bus           (bus),
        .sel           (sel),
        .rx            (rx_internal)
    );
    assign rx = rx_internal;

    // TX Multiplexer: Selects the correct TX channel to drive the bus
    TXMux #(.DW(DW)) u_tx_mux (
        .tx            (tx),
        .sel           (sel),
        .tx_sel        (bus_data)
    );

    // Bus Output Enable Logic: Drives bus with selected TX data if OE is asserted
    BusDriver #(.DW(DW)) u_bus_driver (
        .tx_sel        (bus_data),
        .oe            (oe),
        .bus_drive     (bus_drive)
    );

    assign bus = bus_drive;

endmodule

//------------------------------------------------------------------------------
// RX Demultiplexer
// Routes data from bus to the selected RX channel
//------------------------------------------------------------------------------
module RXDemux #(parameter DW=8) (
    input  [DW-1:0] bus,
    input  [1:0]    sel,
    output [4*DW-1:0] rx
);
    genvar i;
    generate
        for(i=0; i<4; i=i+1) begin: rx_gen
            assign rx[(i+1)*DW-1:i*DW] = (sel == i) ? bus : {DW{1'bz}};
        end
    endgenerate
endmodule

//------------------------------------------------------------------------------
// TX Multiplexer
// Selects the correct TX channel based on SEL
//------------------------------------------------------------------------------
module TXMux #(parameter DW=8) (
    input  [(4*DW)-1:0] tx,
    input  [1:0]        sel,
    output [DW-1:0]     tx_sel
);
    reg [DW-1:0] tx_mux;
    always @(*) begin
        case(sel)
            2'd0: tx_mux = tx[DW-1:0];
            2'd1: tx_mux = tx[(2*DW)-1:DW];
            2'd2: tx_mux = tx[(3*DW)-1:(2*DW)];
            2'd3: tx_mux = tx[(4*DW)-1:(3*DW)];
            default: tx_mux = {DW{1'bz}};
        endcase
    end
    assign tx_sel = tx_mux;
endmodule

//------------------------------------------------------------------------------
// Bus Output Driver
// Drives the bus with selected TX data if output enable is high, else tristate
//------------------------------------------------------------------------------
module BusDriver #(parameter DW=8) (
    input  [DW-1:0] tx_sel,
    input           oe,
    output [DW-1:0] bus_drive
);
    assign bus_drive = oe ? tx_sel : {DW{1'bz}};
endmodule