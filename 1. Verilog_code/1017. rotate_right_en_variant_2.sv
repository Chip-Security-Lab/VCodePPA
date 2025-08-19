//SystemVerilog
module rotate_right_en #(parameter W=8) (
    input wire clk,
    input wire en,
    input wire rst_n,
    input wire [W-1:0] din,
    output reg [W-1:0] dout
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= {W{1'b0}};
    end else begin
        case ({en})
            1'b1: dout <= (W > 1) ? {din[0], din[W-1:1]} : din;
            default: dout <= dout;
        endcase
    end
end

endmodule