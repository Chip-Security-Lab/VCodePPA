module addr_trans_bridge #(parameter DWIDTH=32, AWIDTH=16) (
    input clk, rst_n,
    input [AWIDTH-1:0] src_addr,
    input [DWIDTH-1:0] src_data,
    input src_valid,
    output reg src_ready,
    output reg [AWIDTH-1:0] dst_addr,
    output reg [DWIDTH-1:0] dst_data,
    output reg dst_valid,
    input dst_ready
);
    reg [AWIDTH-1:0] base_addr = 'h1000;  // Example base address
    reg [AWIDTH-1:0] limit_addr = 'h2000; // Example limit
    
    always @(posedge clk) begin
        if (!rst_n) begin
            dst_valid <= 0; src_ready <= 1;
        end else if (src_valid && src_ready) begin
            if (src_addr >= base_addr && src_addr < limit_addr) begin
                dst_addr <= src_addr - base_addr;
                dst_data <= src_data;
                dst_valid <= 1;
                src_ready <= 0;
            end
        end else if (dst_valid && dst_ready) begin
            dst_valid <= 0;
            src_ready <= 1;
        end
    end
endmodule