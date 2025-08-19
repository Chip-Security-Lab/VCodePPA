module pl_reg_stall #(parameter W=4) (
    input clk, rst, load, stall,
    input [W-1:0] new_data,
    output reg [W-1:0] current_data
);
always @(posedge clk or posedge rst) begin
    if (rst) current_data <= 0;
    else if (!stall)
        current_data <= load ? new_data : current_data;
end
endmodule