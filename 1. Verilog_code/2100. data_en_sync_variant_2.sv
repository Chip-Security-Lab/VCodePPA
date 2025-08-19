//SystemVerilog
module data_en_sync #(parameter DW=8) (
    input wire src_clk,
    input wire dst_clk,
    input wire rst,
    input wire [DW-1:0] data,
    input wire data_en,
    output reg [DW-1:0] synced_data
);

    reg en_sync0, en_sync1;
    reg [DW-1:0] data_latch;

    // Optimized Conditional sum subtraction submodule using Boolean algebra
    function [DW-1:0] cond_sum_sub;
        input [DW-1:0] a;
        input [DW-1:0] b;
        integer i;
        reg [DW:0] borrow;
        reg [DW-1:0] diff;
        begin
            borrow[0] = 1'b0;
            for(i=0; i<DW; i=i+1) begin
                // Simplified Boolean expressions:
                // a[i] ^ b[i] ^ borrow[i] remains as XOR is already minimal
                diff[i] = a[i] ^ b[i] ^ borrow[i];
                // borrow[i+1] = (~a[i] & b[i]) | ((~a[i] | b[i]) & borrow[i]);
                // Apply distributive law:
                // = (~a[i] & b[i]) | (~a[i] & borrow[i]) | (b[i] & borrow[i])
                // = (~a[i] & (b[i] | borrow[i])) | (b[i] & borrow[i])
                // = (~a[i] & (b[i] | borrow[i])) | (b[i] & borrow[i])
                // = (~a[i] & (b[i] | borrow[i])) | (b[i] & borrow[i])
                // However, (~a[i] & (b[i] | borrow[i])) | (b[i] & borrow[i]) is equivalent to
                // (~a[i] & b[i]) | (~a[i] & borrow[i]) | (b[i] & borrow[i])
                // This is already minimal, but we can factor for gate reduction:
                // = (~a[i] & (b[i] | borrow[i])) | (b[i] & borrow[i])
                borrow[i+1] = (~a[i] & (b[i] | borrow[i])) | (b[i] & borrow[i]);
            end
            cond_sum_sub = diff;
        end
    endfunction

    // Latch the data with subtraction logic (for demonstration, data_latch <= data - 0)
    always @(posedge src_clk) begin
        if(data_en) data_latch <= data; // data - 0 = data, so direct assignment
    end

    always @(posedge dst_clk) begin
        {en_sync1, en_sync0} <= {en_sync0, data_en};
        if(en_sync1) synced_data <= data_latch;
    end

endmodule