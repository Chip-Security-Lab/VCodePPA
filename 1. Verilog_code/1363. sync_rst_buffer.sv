module sync_rst_buffer (
    input wire clk,
    input wire rst,
    input wire [31:0] data_in,
    input wire load,
    output reg [31:0] data_out
);
    always @(posedge clk) begin
        if (rst)
            data_out <= 32'b0;
        else if (load)
            data_out <= data_in;
    end
endmodule