module pl_reg_divider #(parameter W=4, DIV=4) (
    input clk, rst,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);
reg [DIV-1:0] counter;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 0;
        data_out <= 0;
    end else begin
        counter <= counter + 1;
        if (&counter) data_out <= data_in;
    end
end
endmodule