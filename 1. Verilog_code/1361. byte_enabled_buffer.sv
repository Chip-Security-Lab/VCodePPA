module byte_enabled_buffer (
    input wire clk,
    input wire [31:0] data_in,
    input wire [3:0] byte_en,
    input wire write,
    output reg [31:0] data_out
);
    always @(posedge clk) begin
        if (write) begin
            if (byte_en[0]) data_out[7:0] <= data_in[7:0];
            if (byte_en[1]) data_out[15:8] <= data_in[15:8];
            if (byte_en[2]) data_out[23:16] <= data_in[23:16];
            if (byte_en[3]) data_out[31:24] <= data_in[31:24];
        end
    end
endmodule