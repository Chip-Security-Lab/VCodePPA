//SystemVerilog
module sync_fifo #(parameter DW=8, AW=4) (
    input wr_clk, rd_clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full, empty
);
    // Memory array
    reg [DW-1:0] mem[(1<<AW)-1:0];
    
    // Pipeline stage registers for write path
    reg wr_en_stage1, wr_en_stage2;
    reg [DW-1:0] din_stage1, din_stage2;
    reg [AW-1:0] wr_addr_stage1, wr_addr_stage2;
    reg full_stage1, full_stage2;
    
    // Pipeline stage registers for read path
    reg rd_en_stage1, rd_en_stage2;
    reg [DW-1:0] dout_stage1, dout_stage2;
    reg [AW-1:0] rd_addr_stage1, rd_addr_stage2;
    reg empty_stage1, empty_stage2;
    
    // Binary counters for read and write pointers
    reg [AW:0] wr_ptr_bin=0, rd_ptr_bin=0;
    
    // Gray-coded pointers for clock domain crossing
    reg [AW:0] wr_ptr_gray=0, rd_ptr_gray=0;
    
    // Synchronized pointers (2-FF synchronizers)
    reg [AW:0] rd_ptr_gray_sync1=0, rd_ptr_gray_sync2=0;
    reg [AW:0] wr_ptr_gray_sync1=0, wr_ptr_gray_sync2=0;
    
    // Convert binary to gray code - pipelined implementation
    function [AW:0] bin_to_gray;
        input [AW:0] bin;
        begin
            bin_to_gray = bin ^ (bin >> 1);
        end
    endfunction
    
    // Convert gray to binary - pipelined implementation
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
    
    // Stage 1: Pre-computation and input registration
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en_stage1 <= 0;
            din_stage1 <= 0;
            wr_addr_stage1 <= 0;
        end else begin
            wr_en_stage1 <= wr_en;
            din_stage1 <= din;
            wr_addr_stage1 <= wr_ptr_bin[AW-1:0];
        end
    end
    
    // Stage 2: Memory access preparation
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en_stage2 <= 0;
            din_stage2 <= 0;
            wr_addr_stage2 <= 0;
            full_stage1 <= 0;
        end else begin
            wr_en_stage2 <= wr_en_stage1 && !full;
            din_stage2 <= din_stage1;
            wr_addr_stage2 <= wr_addr_stage1;
            full_stage1 <= full;
        end
    end
    
    // Memory write operation - final pipeline stage
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset not needed for memory array
        end else if (wr_en_stage2 && !full_stage1) begin
            mem[wr_addr_stage2] <= din_stage2;
        end
    end
    
    // Write pointer update - pipelined with the write operation
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en_stage2 && !full_stage1) begin
            wr_ptr_bin <= wr_ptr_bin + 1;
            wr_ptr_gray <= bin_to_gray(wr_ptr_bin + 1);
        end
    end
    
    // Read pipeline stages
    
    // Stage 1: Pre-computation and input registration
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en_stage1 <= 0;
            rd_addr_stage1 <= 0;
        end else begin
            rd_en_stage1 <= rd_en;
            rd_addr_stage1 <= rd_ptr_bin[AW-1:0];
        end
    end
    
    // Stage 2: Memory read prepare
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en_stage2 <= 0;
            rd_addr_stage2 <= 0;
            empty_stage1 <= 1;
        end else begin
            rd_en_stage2 <= rd_en_stage1 && !empty;
            rd_addr_stage2 <= rd_addr_stage1;
            empty_stage1 <= empty;
        end
    end
    
    // Memory read and output - final pipeline stage
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage1 <= 0;
        end else if (rd_en_stage2 && !empty_stage1) begin
            dout_stage1 <= mem[rd_addr_stage2];
        end
    end
    
    // Output register stage
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage2 <= 0;
        end else begin
            dout_stage2 <= dout_stage1;
        end
    end
    
    // Read pointer update - pipelined with read operation
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en_stage2 && !empty_stage1) begin
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gray <= bin_to_gray(rd_ptr_bin + 1);
        end
    end
    
    // Clock domain crossing synchronizers - now pipelined
    
    // Pipeline stage 1: Capture pointers
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
        end
    end
    
    // Pipeline stage 2: Complete synchronization
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end
    
    // Similar pipelining for read pointer synchronization
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync1 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
        end
    end
    
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end
    
    // Pipelined gray to binary conversion for status flags
    reg [AW:0] rd_ptr_bin_sync_stage1, rd_ptr_bin_sync_stage2;
    reg [AW:0] wr_ptr_bin_sync_stage1, wr_ptr_bin_sync_stage2;
    
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin_sync_stage1 <= 0;
            rd_ptr_bin_sync_stage2 <= 0;
        end else begin
            rd_ptr_bin_sync_stage1 <= gray_to_bin(rd_ptr_gray_sync2);
            rd_ptr_bin_sync_stage2 <= rd_ptr_bin_sync_stage1;
        end
    end
    
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin_sync_stage1 <= 0;
            wr_ptr_bin_sync_stage2 <= 0;
        end else begin
            wr_ptr_bin_sync_stage1 <= gray_to_bin(wr_ptr_gray_sync2);
            wr_ptr_bin_sync_stage2 <= wr_ptr_bin_sync_stage1;
        end
    end
    
    // Pipelined full/empty flag generation
    reg full_int, empty_int;
    
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            full_int <= 0;
        end else begin
            full_int <= (wr_ptr_bin[AW-1:0] == rd_ptr_bin_sync_stage2[AW-1:0]) && 
                       (wr_ptr_bin[AW] != rd_ptr_bin_sync_stage2[AW]);
        end
    end
    
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            empty_int <= 1;
        end else begin
            empty_int <= (rd_ptr_bin[AW-1:0] == wr_ptr_bin_sync_stage2[AW-1:0]) && 
                        (rd_ptr_bin[AW] == wr_ptr_bin_sync_stage2[AW]);
        end
    end
    
    // Output assignments
    assign full = full_int;
    assign empty = empty_int;
    assign dout = dout_stage2;
    
endmodule