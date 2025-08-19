module sync_fifo #(parameter DW=8, AW=4) (
    input wr_clk, rd_clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full, empty
);
    // Memory array
    reg [DW-1:0] mem[(1<<AW)-1:0];
    
    // Binary counters for read and write pointers
    reg [AW:0] wr_ptr_bin=0, rd_ptr_bin=0;
    
    // Gray-coded pointers for clock domain crossing
    reg [AW:0] wr_ptr_gray=0, rd_ptr_gray=0;
    
    // Synchronized pointers (2-FF synchronizers)
    reg [AW:0] rd_ptr_gray_sync1=0, rd_ptr_gray_sync2=0;
    reg [AW:0] wr_ptr_gray_sync1=0, wr_ptr_gray_sync2=0;
    
    // Convert binary to gray code
    function [AW:0] bin_to_gray;
        input [AW:0] bin;
        begin
            bin_to_gray = bin ^ (bin >> 1);
        end
    endfunction
    
    // Convert gray to binary
    function [AW:0] gray_to_bin;
        input [AW:0] gray;
        reg [AW:0] bin;
        integer i;
        begin
            bin = gray;
            for (i = 1; i <= AW; i = i + 1)
                bin = bin ^ (gray >> i);
            gray_to_bin = bin;
        end
    endfunction
    
    // Write pointer logic
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr_bin[AW-1:0]] <= din;
            wr_ptr_bin <= wr_ptr_bin + 1;
            wr_ptr_gray <= bin_to_gray(wr_ptr_bin + 1);
        end
    end
    
    // Read pointer logic
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gray <= bin_to_gray(rd_ptr_bin + 1);
        end
    end
    
    // Synchronize write pointer to read clock domain
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end
    
    // Synchronize read pointer to write clock domain
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end
    
    // Data output
    assign dout = mem[rd_ptr_bin[AW-1:0]];
    
    // Calculate full flag using synchronized read pointer in write domain
    wire [AW:0] rd_ptr_bin_sync = gray_to_bin(rd_ptr_gray_sync2);
    assign full = (wr_ptr_bin[AW-1:0] == rd_ptr_bin_sync[AW-1:0]) && 
                 (wr_ptr_bin[AW] != rd_ptr_bin_sync[AW]);
    
    // Calculate empty flag using synchronized write pointer in read domain
    wire [AW:0] wr_ptr_bin_sync = gray_to_bin(wr_ptr_gray_sync2);
    assign empty = (rd_ptr_bin == wr_ptr_bin_sync);
    
endmodule