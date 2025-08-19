//SystemVerilog
//=============================================================================
// Module: RD1_Top
// Description: Top level module for the registered data path
// Standard: IEEE 1364-2005
//=============================================================================
module RD1_Top #(
    parameter DW = 8
)(
    input wire clk,
    input wire rst,
    input wire [DW-1:0] din,
    output wire [DW-1:0] dout
);

    // Internal connections
    wire [DW-1:0] reset_mux_out;
    
    // Buffered signals for high fanout reduction
    reg rst_buf1, rst_buf2;
    reg [DW-1:0] din_buf1, din_buf2;
    reg [DW-1:0] reset_mux_out_buf;
    
    // Register high fanout signals to reduce loading
    always @(posedge clk) begin
        rst_buf1 <= rst;
        rst_buf2 <= rst;
        din_buf1 <= din;
        din_buf2 <= din;
        reset_mux_out_buf <= reset_mux_out;
    end

    // Instantiate reset logic module
    ResetLogic #(
        .DW(DW)
    ) reset_logic_inst (
        .rst(rst_buf1),
        .din(din_buf1),
        .reset_mux_out(reset_mux_out)
    );

    // Instantiate register module
    RegisterStage #(
        .DW(DW)
    ) register_stage_inst (
        .clk(clk),
        .data_in(reset_mux_out_buf),
        .data_out(dout)
    );

endmodule

//=============================================================================
// Module: ResetLogic
// Description: Handles input data muxing based on reset signal
// Standard: IEEE 1364-2005
//=============================================================================
module ResetLogic #(
    parameter DW = 8
)(
    input wire rst,
    input wire [DW-1:0] din,
    output wire [DW-1:0] reset_mux_out
);

    // Buffer for high fanout parameter
    wire [3:0] DW_buf;
    assign DW_buf = DW;

    // Reset multiplexer logic with balanced loading
    // Split implementation for larger bus widths
    generate
        if (DW > 4) begin: gen_wide_mux
            wire [3:0] rst_fanout;
            assign rst_fanout = {4{rst}};
            
            assign reset_mux_out[3:0] = rst_fanout[0] ? 4'b0000 : din[3:0];
            assign reset_mux_out[DW-1:4] = rst_fanout[1] ? {(DW-4){1'b0}} : din[DW-1:4];
        end
        else begin: gen_narrow_mux
            assign reset_mux_out = rst ? {DW{1'b0}} : din;
        end
    endgenerate

endmodule

//=============================================================================
// Module: RegisterStage
// Description: Registers data on clock edge
// Standard: IEEE 1364-2005
//=============================================================================
module RegisterStage #(
    parameter DW = 8
)(
    input wire clk,
    input wire [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);

    // Split register implementation to balance loading
    // For wider bus widths, use separate always blocks
    generate
        if (DW > 4) begin: gen_wide_reg
            always @(posedge clk) begin
                data_out[3:0] <= data_in[3:0];
            end
            
            always @(posedge clk) begin
                data_out[DW-1:4] <= data_in[DW-1:4];
            end
        end
        else begin: gen_narrow_reg
            always @(posedge clk) begin
                data_out <= data_in;
            end
        end
    endgenerate

endmodule