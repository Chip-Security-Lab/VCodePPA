//SystemVerilog
module dram_write_mask #(
    parameter DATA_WIDTH = 64,
    parameter MASK_WIDTH = 8
)(
    input clk,
    input [MASK_WIDTH-1:0] mask,
    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out
);

    reg [DATA_WIDTH-1:0] masked_data;

    always @(posedge clk) begin
        for (int i = 0; i < MASK_WIDTH; i++) begin
            masked_data[i*8 +: 8] = mask[i] ? data_in[i*8 +: 8] : 8'b0;
        end
    end

    assign data_out = masked_data;

endmodule