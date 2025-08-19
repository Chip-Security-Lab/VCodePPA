//SystemVerilog
module DiffLatch #(parameter DW=8) (
    input clk,
    input rst_n,
    input [DW-1:0] d_p, d_n,
    output reg [DW-1:0] q,
    output reg valid
);

reg [DW-1:0] d_p_stage1, d_n_stage1;
reg valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d_p_stage1 <= {DW{1'b0}};
        d_n_stage1 <= {DW{1'b0}};
        valid_stage1 <= 1'b0;
        q <= {DW{1'b0}};
        valid <= 1'b0;
    end else begin
        d_p_stage1 <= d_p;
        d_n_stage1 <= d_n;
        valid_stage1 <= 1'b1;
        q <= d_p_stage1 ^ d_n_stage1;
        valid <= valid_stage1;
    end
end

endmodule