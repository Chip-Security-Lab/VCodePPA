module ring_counter_bidirectional (
    input clk, dir, rst,
    output reg [3:0] shift_reg
);
always @(posedge clk) begin
    if (rst) shift_reg <= 4'b0001;
    else shift_reg <= dir ? {shift_reg[2:0], shift_reg[3]} 
                         : {shift_reg[0], shift_reg[3:1]};
end
endmodule
