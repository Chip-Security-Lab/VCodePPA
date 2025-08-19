//SystemVerilog
//-----------------------------------------------------------------------------
// Top-level Module: RstInitMux
// Description: Reset/Init Mux with hierarchical structure
//-----------------------------------------------------------------------------
module RstInitMux #(
    parameter DW = 8
)(
    input                  clk,
    input                  rst,
    input       [2:0]      sel,
    input  [7:0][DW-1:0]   din,
    output [DW-1:0]        dout
);

    // Internal signal for mux output
    wire [DW-1:0] mux_dout;

    // Instantiate the data multiplexer submodule
    RstInitMux_Mux #(
        .DW(DW)
    ) u_mux (
        .sel    (sel),
        .din    (din),
        .dout   (mux_dout)
    );

    // Instantiate the output register submodule with reset logic
    RstInitMux_Reg #(
        .DW(DW)
    ) u_reg (
        .clk    (clk),
        .rst    (rst),
        .din0   (din[0]),
        .din_sel(mux_dout),
        .dout   (dout)
    );

endmodule

//-----------------------------------------------------------------------------
// Submodule: RstInitMux_Mux
// Description: 8-to-1 Multiplexer for data selection
//-----------------------------------------------------------------------------
module RstInitMux_Mux #(
    parameter DW = 8
)(
    input       [2:0]      sel,
    input  [7:0][DW-1:0]   din,
    output reg [DW-1:0]    dout
);
    always @(*) begin
        case (sel)
            3'd0: dout = din[0];
            3'd1: dout = din[1];
            3'd2: dout = din[2];
            3'd3: dout = din[3];
            3'd4: dout = din[4];
            3'd5: dout = din[5];
            3'd6: dout = din[6];
            3'd7: dout = din[7];
            default: dout = {DW{1'b0}};
        endcase
    end
endmodule

//-----------------------------------------------------------------------------
// Submodule: RstInitMux_Reg
// Description: Register with synchronous reset and muxed data input
//-----------------------------------------------------------------------------
module RstInitMux_Reg #(
    parameter DW = 8
)(
    input                  clk,
    input                  rst,
    input  [DW-1:0]        din0,      // Reset/init value
    input  [DW-1:0]        din_sel,   // Muxed selected value
    output reg [DW-1:0]    dout
);
    always @(posedge clk) begin
        if (rst)
            dout <= din0;
        else
            dout <= din_sel;
    end
endmodule