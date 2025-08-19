//SystemVerilog
module dual_clk_fifo #(parameter WIDTH=32, DEPTH=8) (
    input wr_clk, rd_clk, rst_n,
    input [WIDTH-1:0] wr_data,
    input wr_en,
    output reg wr_full,
    output reg [WIDTH-1:0] rd_data,
    input rd_en,
    output reg rd_empty
);
    // Memory array
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    
    // Write domain pointers
    reg [$clog2(DEPTH):0] wr_ptr_bin = 0;
    reg [$clog2(DEPTH):0] wr_ptr_gray = 0;
    
    // Read domain pointers
    reg [$clog2(DEPTH):0] rd_ptr_bin = 0;
    reg [$clog2(DEPTH):0] rd_ptr_gray = 0;

    // Synchronization registers
    reg [$clog2(DEPTH):0] rd_ptr_gray_sync1 = 0, rd_ptr_gray_sync2 = 0;
    reg [$clog2(DEPTH):0] wr_ptr_gray_sync1 = 0, wr_ptr_gray_sync2 = 0;

    // Gray code conversion function
    function [$clog2(DEPTH):0] bin2gray(input [$clog2(DEPTH):0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Synchronize read pointer
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // Synchronize write pointer
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // Write logic
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !wr_full) begin
            mem[wr_ptr_bin[$clog2(DEPTH)-1:0]] <= wr_data;
            wr_ptr_bin <= wr_ptr_bin + 1;
            wr_ptr_gray <= bin2gray(wr_ptr_bin);
        end
    end

    // Read logic
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && !rd_empty) begin
            rd_data <= mem[rd_ptr_bin[$clog2(DEPTH)-1:0]];
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gray <= bin2gray(rd_ptr_bin);
        end
    end

    // Full flag logic
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_full <= 0;
        end else begin
            wr_full <= (wr_ptr_gray[$clog2(DEPTH)] != rd_ptr_gray_sync2[$clog2(DEPTH)]) &&
                       (wr_ptr_gray[$clog2(DEPTH)-1] != rd_ptr_gray_sync2[$clog2(DEPTH)-1]) &&
                       (wr_ptr_gray[$clog2(DEPTH)-2:0] == rd_ptr_gray_sync2[$clog2(DEPTH)-2:0]);
        end
    end

    // Empty flag logic
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_empty <= 1;
        end else begin
            rd_empty <= (rd_ptr_gray == wr_ptr_gray_sync2);
        end
    end
endmodule