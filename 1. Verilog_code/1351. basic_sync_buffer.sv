module basic_sync_buffer (
    input wire clk,
    input wire [7:0] data_in,
    input wire write_en,
    output reg [7:0] data_out
);
    always @(posedge clk) begin
        if (write_en)
            data_out <= data_in;
    end
endmodule