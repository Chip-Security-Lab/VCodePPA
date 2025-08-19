module IVMU_NestingCtrl #(parameter LVL=3) (
    input clk, rst,
    input [LVL-1:0] int_lvl,
    output reg [LVL-1:0] current_lvl
);
always @(posedge clk or posedge rst) begin
    if (rst) current_lvl <= 0;
    else if (|int_lvl) begin
        if (int_lvl > current_lvl)
            current_lvl <= int_lvl;
    end else current_lvl <= 0;
end
endmodule
