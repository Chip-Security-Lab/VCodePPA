module barrel_shifter_sync_cl (
    input clk, rst_n, en,
    input [7:0] data_in,
    input [2:0] shift_amount,
    output reg [7:0] data_out
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) data_out <= 0;
    else if (en) data_out <= (data_in << shift_amount) | 
                            (data_in >> (8 - shift_amount));
end
endmodule