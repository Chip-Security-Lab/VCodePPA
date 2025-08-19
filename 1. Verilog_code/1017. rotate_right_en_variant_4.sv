//SystemVerilog
module rotate_right_en #(parameter W=8) (
    input clk,
    input en,
    input rst_n,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    wire [W-1:0] rotated;
    assign rotated = {din[0], din[W-1:1]};
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= {W{1'b0}};
        else if (en)
            dout <= rotated;
    end
endmodule