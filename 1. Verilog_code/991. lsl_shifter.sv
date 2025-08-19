module lsl_shifter(
    input wire clk, rst_n, en,
    input wire [7:0] data_in,
    input wire [2:0] shift_amt,
    output reg [7:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'b0;
        else if (en)
            data_out <= data_in << shift_amt;
    end
endmodule