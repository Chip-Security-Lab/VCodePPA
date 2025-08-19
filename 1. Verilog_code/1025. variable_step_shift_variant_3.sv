//SystemVerilog
module variable_step_shift #(parameter W=8) (
    input clk,
    input [1:0] step,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
always @(posedge clk) begin
    if (step == 2'd0) begin
        dout <= din;
    end else if (step == 2'd1) begin
        dout <= {din[W-2:0], 1'b0};
    end else if (step == 2'd2) begin
        dout <= {din[W-3:0], 2'b00};
    end else if (step == 2'd3) begin
        dout <= {din[W-5:0], 4'b0000};
    end else begin
        dout <= {W{1'b0}};
    end
end
endmodule