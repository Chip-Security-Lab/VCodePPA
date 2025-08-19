//SystemVerilog
module cdc_fifo_ctrl #(parameter DEPTH = 8) (
    input wire wr_clk,
    input wire rd_clk,
    input wire reset,
    input wire write,
    input wire read,
    output wire full,
    output wire empty,
    output reg [$clog2(DEPTH)-1:0] wptr,
    output reg [$clog2(DEPTH)-1:0] rptr
);
    localparam PTR_WIDTH = 8;

    reg [PTR_WIDTH-1:0] wptr_bin, rptr_bin;
    reg [PTR_WIDTH-1:0] wptr_gray, rptr_gray;
    reg [PTR_WIDTH-1:0] wptr_gray_sync1, wptr_gray_sync2;
    reg [PTR_WIDTH-1:0] rptr_gray_sync1, rptr_gray_sync2;

    reg [PTR_WIDTH-1:0] sub_lut [0:65535];

    integer i, j;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                sub_lut[{i, j}] = i - j;
            end
        end
    end

    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        integer k;
        begin
            gray2bin = gray;
            for (k = PTR_WIDTH-2; k >= 0; k = k - 1) begin
                gray2bin[k] = gray[k] ^ gray2bin[k+1];
            end
        end
    endfunction

    // Merge all wr_clk domain logic into one always block
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            wptr_bin <= 0;
            wptr <= 0;
            wptr_gray <= 0;
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end else begin
            // Write pointer logic
            if (write && !full) begin
                wptr_bin <= wptr_bin + 1'b1;
                wptr <= wptr_bin[$clog2(DEPTH)-1:0] + 1'b1;
                wptr_gray <= bin2gray(wptr_bin + 1'b1);
            end
            // Synchronizer for rptr_gray
            {rptr_gray_sync1, rptr_gray_sync2} <= {rptr_gray, rptr_gray_sync1};
        end
    end

    // Merge all rd_clk domain logic into one always block
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            rptr_bin <= 0;
            rptr <= 0;
            rptr_gray <= 0;
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end else begin
            // Read pointer logic
            if (read && !empty) begin
                rptr_bin <= rptr_bin + 1'b1;
                rptr <= rptr_bin[$clog2(DEPTH)-1:0] + 1'b1;
                rptr_gray <= bin2gray(rptr_bin + 1'b1);
            end
            // Synchronizer for wptr_gray
            {wptr_gray_sync1, wptr_gray_sync2} <= {wptr_gray, wptr_gray_sync1};
        end
    end

    wire [PTR_WIDTH-1:0] wptr_bin_sync, rptr_bin_sync;
    assign wptr_bin_sync = gray2bin(wptr_gray_sync2);
    assign rptr_bin_sync = gray2bin(rptr_gray_sync2);

    wire [PTR_WIDTH-1:0] ptr_diff_wr, ptr_diff_rd;
    assign ptr_diff_wr = sub_lut[{wptr_bin, rptr_bin_sync}];
    assign ptr_diff_rd = sub_lut[{wptr_bin_sync, rptr_bin}];

    assign full = (bin2gray(wptr_bin + 1'b1) == {~rptr_gray_sync2[$clog2(DEPTH)-1:$clog2(DEPTH)-2],
                                                  rptr_gray_sync2[$clog2(DEPTH)-3:0]});
    assign empty = (rptr_gray == wptr_gray_sync2);

endmodule