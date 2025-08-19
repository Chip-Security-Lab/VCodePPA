//SystemVerilog
// Top-level module: Hierarchical Register with Enable and Multiplexer (Layered Structure)

module RegEnMux #(parameter DW=8) (
    input wire clk,
    input wire en,
    input wire [1:0] sel,
    input wire [3:0][DW-1:0] din,
    output wire [DW-1:0] dout
);

    // Internal signals for inter-module connectivity
    wire [DW-1:0] mux_to_reg;

    // Multiplexer submodule instance
    RegEnMux_Mux #(.DW(DW)) u_mux (
        .sel(sel),
        .din(din),
        .mux_out(mux_to_reg)
    );

    // Register with enable submodule instance
    RegEnMux_Reg #(.DW(DW)) u_reg (
        .clk(clk),
        .en(en),
        .din(mux_to_reg),
        .dout(dout)
    );

endmodule

// ---------------------------------------------------------------------------
// 4-to-1 Multiplexer Submodule
// Function: Selects one of four DW-bit wide inputs based on sel signal
module RegEnMux_Mux #(parameter DW=8) (
    input wire [1:0] sel,
    input wire [3:0][DW-1:0] din,
    output wire [DW-1:0] mux_out
);
    assign mux_out = din[sel];
endmodule

// ---------------------------------------------------------------------------
// Register with Enable Submodule
// Function: DW-bit register, loads input on rising clock edge when enable is high
module RegEnMux_Reg #(parameter DW=8) (
    input wire clk,
    input wire en,
    input wire [DW-1:0] din,
    output reg [DW-1:0] dout
);
    always @(posedge clk) begin
        if (en)
            dout <= din;
    end
endmodule