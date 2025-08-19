module sync_shift_rst #(parameter DEPTH=4) (
    input wire clk,
    input wire rst,
    input wire serial_in,
    output reg [DEPTH-1:0] shift_reg
);
integer i;
always @(posedge clk) begin
    if (rst)
        shift_reg <= {DEPTH{1'b0}};
    else begin
        shift_reg[0] <= serial_in;
        for(i=1;i<DEPTH;i=i+1)
            shift_reg[i] <= shift_reg[i-1];
    end
end
endmodule
