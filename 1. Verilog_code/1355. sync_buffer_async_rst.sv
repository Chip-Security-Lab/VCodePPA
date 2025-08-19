module sync_buffer_async_rst (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire load,
    output reg [7:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'b0;
        else if (load)
            data_out <= data_in;
    end
endmodule