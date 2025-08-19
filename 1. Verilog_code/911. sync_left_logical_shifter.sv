module sync_left_logical_shifter #(
    parameter DATA_WIDTH = 8,
    parameter SHIFT_WIDTH = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [SHIFT_WIDTH-1:0] shift_amount,
    output reg [DATA_WIDTH-1:0] data_out
);
    // Synchronous operation with active-low reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {DATA_WIDTH{1'b0}}; // Clear output on reset
        else
            data_out <= data_in << shift_amount; // Left logical shift
    end
endmodule