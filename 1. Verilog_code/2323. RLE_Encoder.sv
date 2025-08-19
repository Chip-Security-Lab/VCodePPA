module RLE_Encoder (
    input clk, rst_n, en,
    input [7:0] data_in,
    output reg [15:0] data_out,
    output valid
);
reg [7:0] prev_data;
reg [7:0] counter;
always @(posedge clk) begin
    if (!rst_n) {prev_data, counter} <= 0;
    else if (en) begin
        if (data_in == prev_data && counter < 255) counter <= counter + 1;
        else begin
            data_out <= {counter, prev_data};
            prev_data <= data_in;
            counter <= 0;
        end
    end
end
assign valid = (counter != 0);
endmodule
