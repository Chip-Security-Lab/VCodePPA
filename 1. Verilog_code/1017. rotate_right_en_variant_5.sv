//SystemVerilog
module rotate_right_en #(parameter W=8) (
    input  wire              clk,
    input  wire              en,
    input  wire              rst_n,
    input  wire [W-1:0]      din,
    output wire [W-1:0]      dout
);

reg [W-1:0] din_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        din_reg <= {W{1'b0}};
    end else if (en) begin
        din_reg <= din;
    end
end

assign dout = {din_reg[0], din_reg[W-1:1]};

endmodule