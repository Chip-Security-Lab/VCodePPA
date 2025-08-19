//SystemVerilog
module bin2onehot #(parameter IN_WIDTH = 4) (
    input wire clk,
    input wire rst_n,
    input wire [IN_WIDTH-1:0] bin_in,
    output reg [(2**IN_WIDTH)-1:0] onehot_out
);

    wire [IN_WIDTH-1:0] bin_in_complement;
    wire [(2**IN_WIDTH)-1:0] onehot_base;
    wire [(2**IN_WIDTH)-1:0] onehot_shifted;

    // Calculate two's complement for subtraction
    assign bin_in_complement = ~bin_in + 4'd1;

    // Base one-hot pattern (LSB is 1)
    assign onehot_base = {{(2**IN_WIDTH-1){1'b0}}, 1'b1};

    // Use two's complement addition for subtraction in shift operation
    assign onehot_shifted = onehot_base << bin_in;

    always @(posedge clk or negedge rst_n) begin
        onehot_out <= (!rst_n) ? {(2**IN_WIDTH){1'b0}} : onehot_shifted;
    end

endmodule