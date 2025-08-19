module variable_step_shift #(parameter W=8) (
    input clk,
    input [1:0] step,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
always @(posedge clk) begin
    case(step)
        0: dout <= din;
        1: dout <= {din[6:0], 1'b0};
        2: dout <= {din[5:0], 2'b00};
        3: dout <= {din[3:0], 4'b0000};
    endcase
end
endmodule