//SystemVerilog
module sync_2ff_en #(parameter DW=8) (
    input  wire             src_clk,
    input  wire             dst_clk,
    input  wire             rst_n,
    input  wire             en,
    input  wire [DW-1:0]    async_in,
    output reg  [DW-1:0]    synced_out
);
    reg [DW-1:0] sync_ff;

    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            synced_out <= {DW{1'b0}};
            sync_ff    <= {DW{1'b0}};
        end else if (en) begin
            sync_ff    <= async_in;
            synced_out <= sync_ff;
        end
    end
endmodule