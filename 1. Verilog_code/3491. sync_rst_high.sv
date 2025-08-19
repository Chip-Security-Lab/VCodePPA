module sync_rst_high #(parameter DATA_WIDTH=8) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
always @(posedge clk) begin
    if (!rst_n)
        data_out <= {DATA_WIDTH{1'b0}};
    else if (en)
        data_out <= data_in;
end
endmodule
