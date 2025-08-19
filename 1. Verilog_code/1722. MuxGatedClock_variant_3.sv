//SystemVerilog
module MuxGatedClock #(parameter W=4) (
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
    always @(posedge clk_en) begin
        data_reg <= din[sel];
        q <= data_reg;
    end

endmodule