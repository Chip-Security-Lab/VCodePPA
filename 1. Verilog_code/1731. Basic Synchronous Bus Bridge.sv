module sync_bus_bridge #(parameter DWIDTH=32, AWIDTH=8) (
    input clk, rst_n,
    input [AWIDTH-1:0] src_addr, dst_addr,
    input [DWIDTH-1:0] src_data,
    input src_valid, dst_ready,
    output reg [DWIDTH-1:0] dst_data,
    output reg src_ready, dst_valid
);
    always @(posedge clk) begin
        if (!rst_n) begin
            dst_data <= 0; dst_valid <= 0; src_ready <= 1;
        end else if (src_valid && src_ready) begin
            dst_data <= src_data; dst_valid <= 1; src_ready <= 0;
        end else if (dst_valid && dst_ready) begin
            dst_valid <= 0; src_ready <= 1;
        end
    end
endmodule