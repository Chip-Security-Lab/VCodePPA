//SystemVerilog
module sync_bus_bridge #(parameter DWIDTH=32, AWIDTH=8) (
    input clk, rst_n,
    input [AWIDTH-1:0] src_addr, dst_addr,
    input [DWIDTH-1:0] src_data,
    input src_valid, dst_ready,
    output reg [DWIDTH-1:0] dst_data,
    output reg src_ready, dst_valid
);
    // Lookup table for subtraction
    reg [DWIDTH-1:0] lut_sub [0:255]; // 256 entries for 8-bit input

    // Initialize the lookup table
    initial begin
        integer i, j;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                lut_sub[i] = i - j; // Populate the LUT with subtraction results
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            dst_data <= 0; 
            dst_valid <= 0; 
            src_ready <= 1;
        end else if (src_valid && src_ready) begin
            dst_data <= lut_sub[src_data[AWIDTH-1:0]]; // Use LUT for subtraction
            dst_valid <= 1; 
            src_ready <= 0;
        end else if (dst_valid && dst_ready) begin
            dst_valid <= 0; 
            src_ready <= 1;
        end
    end
endmodule