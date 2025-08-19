module sync_low_rst_counter #(parameter COUNT_WIDTH=8)(
    input wire clk,
    input wire rst_n,
    input wire load,
    input wire [COUNT_WIDTH-1:0] load_value,
    output reg [COUNT_WIDTH-1:0] counter
);
always @(posedge clk) begin
    if (!rst_n)
        counter <= {COUNT_WIDTH{1'b0}};
    else if (load)
        counter <= load_value;
    else
        counter <= counter + 1'b1;
end
endmodule
