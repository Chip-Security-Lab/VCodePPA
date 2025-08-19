//SystemVerilog
module MuxGatedClock #(
    parameter W = 4
) (
    input wire gclk,
    input wire en,
    input wire [3:0][W-1:0] din,
    input wire [1:0] sel,
    output reg [W-1:0] q
);

    // Clock gating logic
    wire clk_en;
    assign clk_en = gclk & en;

    // Data path pipeline
    reg [W-1:0] data_reg;
    reg [1:0] sel_reg;

    // Pipeline stage 1: Register inputs
    always @(posedge clk_en) begin
        sel_reg <= sel;
        data_reg <= din[sel];
    end

    // Pipeline stage 2: Output register
    always @(posedge clk_en) begin
        q <= data_reg;
    end

endmodule