//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module sync_fifo #(parameter DW=8, AW=4) (
    input wr_clk, rd_clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full, empty
);
    // Memory array
    reg [DW-1:0] mem[(1<<AW)-1:0];
    
    // Binary counters for read and write pointers with pipelined stages
    reg [AW:0] wr_ptr_bin_stage1=0, wr_ptr_bin_stage2=0;
    reg [AW:0] rd_ptr_bin_stage1=0, rd_ptr_bin_stage2=0;
    
    // Gray-coded pointers with pipelined stages
    reg [AW:0] wr_ptr_gray_stage1=0, wr_ptr_gray_stage2=0;
    reg [AW:0] rd_ptr_gray_stage1=0, rd_ptr_gray_stage2=0;
    
    // Synchronized pointers with additional pipeline stages
    reg [AW:0] rd_ptr_gray_sync1=0, rd_ptr_gray_sync2=0, rd_ptr_gray_sync3=0;
    reg [AW:0] wr_ptr_gray_sync1=0, wr_ptr_gray_sync2=0, wr_ptr_gray_sync3=0;
    
    // Pipeline control signals
    reg wr_valid_stage1=0, wr_valid_stage2=0;
    reg rd_valid_stage1=0, rd_valid_stage2=0;
    
    // Pipeline data registers
    reg [DW-1:0] din_stage1=0, din_stage2=0;
    reg [DW-1:0] dout_stage1=0, dout_stage2=0;
    
    // Pipeline address registers
    reg [AW-1:0] wr_addr_stage1=0, wr_addr_stage2=0;
    reg [AW-1:0] rd_addr_stage1=0, rd_addr_stage2=0;
    
    // Convert binary to gray code using pipelined barrel shifter
    function [AW:0] bin_to_gray;
        input [AW:0] bin;
        begin
            bin_to_gray = bin ^ {1'b0, bin[AW:1]};
        end
    endfunction
    
    // Convert gray to binary using pipelined barrel shifter
    function [AW:0] gray_to_bin_stage1;
        input [AW:0] gray;
        reg [AW:0] bin;
        begin
            bin = gray;
            // First stage of barrel shifter
            if (AW >= 1) bin = bin ^ {bin[AW-1:0], 1'b0};
            if (AW >= 2) bin = bin ^ {{2{1'b0}}, bin[AW:2]};
            gray_to_bin_stage1 = bin;
        end
    endfunction
    
    function [AW:0] gray_to_bin_stage2;
        input [AW:0] partial_bin;
        reg [AW:0] bin;
        begin
            bin = partial_bin;
            // Second stage of barrel shifter
            if (AW >= 4) bin = bin ^ {{4{1'b0}}, bin[AW:4]};
            if (AW >= 8) bin = bin ^ {{8{1'b0}}, bin[AW:8]};
            if (AW >= 16) bin = bin ^ {{16{1'b0}}, bin[AW:16]};
            gray_to_bin_stage2 = bin;
        end
    endfunction
    
    // Stage 1: Write pointer increment and gray code conversion - first stage
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin_stage1 <= 0;
            wr_ptr_gray_stage1 <= 0;
            wr_valid_stage1 <= 0;
            din_stage1 <= 0;
            wr_addr_stage1 <= 0;
        end else begin
            wr_valid_stage1 <= wr_en && !full;
            if (wr_en && !full) begin
                wr_addr_stage1 <= wr_ptr_bin_stage1[AW-1:0];
                din_stage1 <= din;
                wr_ptr_bin_stage1 <= wr_ptr_bin_stage1 + 1'b1;
                wr_ptr_gray_stage1 <= bin_to_gray(wr_ptr_bin_stage1 + 1'b1);
            end
        end
    end
    
    // Stage 2: Write pointer - second stage and memory write
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin_stage2 <= 0;
            wr_ptr_gray_stage2 <= 0;
            wr_valid_stage2 <= 0;
            wr_addr_stage2 <= 0;
            din_stage2 <= 0;
        end else begin
            wr_valid_stage2 <= wr_valid_stage1;
            wr_ptr_bin_stage2 <= wr_ptr_bin_stage1;
            wr_ptr_gray_stage2 <= wr_ptr_gray_stage1;
            wr_addr_stage2 <= wr_addr_stage1;
            din_stage2 <= din_stage1;
            
            if (wr_valid_stage2) begin
                mem[wr_addr_stage2] <= din_stage2;
            end
        end
    end
    
    // Stage 1: Read pointer increment and gray code conversion - first stage
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin_stage1 <= 0;
            rd_ptr_gray_stage1 <= 0;
            rd_valid_stage1 <= 0;
            rd_addr_stage1 <= 0;
        end else begin
            rd_valid_stage1 <= rd_en && !empty;
            if (rd_en && !empty) begin
                rd_addr_stage1 <= rd_ptr_bin_stage1[AW-1:0];
                rd_ptr_bin_stage1 <= rd_ptr_bin_stage1 + 1'b1;
                rd_ptr_gray_stage1 <= bin_to_gray(rd_ptr_bin_stage1 + 1'b1);
            end
        end
    end
    
    // Stage 2: Read pointer - second stage and data read
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin_stage2 <= 0;
            rd_ptr_gray_stage2 <= 0;
            rd_valid_stage2 <= 0;
            rd_addr_stage2 <= 0;
            dout_stage1 <= 0;
        end else begin
            rd_valid_stage2 <= rd_valid_stage1;
            rd_ptr_bin_stage2 <= rd_ptr_bin_stage1;
            rd_ptr_gray_stage2 <= rd_ptr_gray_stage1;
            rd_addr_stage2 <= rd_addr_stage1;
            
            if (rd_valid_stage1) begin
                dout_stage1 <= mem[rd_addr_stage1];
            end
        end
    end
    
    // Output register stage
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage2 <= 0;
        end else if (rd_valid_stage2) begin
            dout_stage2 <= dout_stage1;
        end
    end
    
    // Pipelined synchronization of write pointer to read clock domain
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
            wr_ptr_gray_sync3 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray_stage2;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
            wr_ptr_gray_sync3 <= wr_ptr_gray_sync2;
        end
    end
    
    // Pipelined synchronization of read pointer to write clock domain
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
            rd_ptr_gray_sync3 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray_stage2;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
            rd_ptr_gray_sync3 <= rd_ptr_gray_sync2;
        end
    end
    
    // Pipelined gray-to-binary conversion for synchronized pointers
    reg [AW:0] rd_ptr_bin_sync_stage1=0, rd_ptr_bin_sync_stage2=0;
    reg [AW:0] wr_ptr_bin_sync_stage1=0, wr_ptr_bin_sync_stage2=0;
    
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin_sync_stage1 <= 0;
            rd_ptr_bin_sync_stage2 <= 0;
        end else begin
            rd_ptr_bin_sync_stage1 <= gray_to_bin_stage1(rd_ptr_gray_sync3);
            rd_ptr_bin_sync_stage2 <= gray_to_bin_stage2(rd_ptr_bin_sync_stage1);
        end
    end
    
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin_sync_stage1 <= 0;
            wr_ptr_bin_sync_stage2 <= 0;
        end else begin
            wr_ptr_bin_sync_stage1 <= gray_to_bin_stage1(wr_ptr_gray_sync3);
            wr_ptr_bin_sync_stage2 <= gray_to_bin_stage2(wr_ptr_bin_sync_stage1);
        end
    end
    
    // Data output with pipeline stage
    assign dout = dout_stage2;
    
    // Pipelined FIFO status logic
    reg full_stage1=0, full_stage2=0;
    reg empty_stage1=0, empty_stage2=0;
    
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            full_stage1 <= 0;
            full_stage2 <= 0;
        end else begin
            // Stage 1 calculation
            full_stage1 <= (wr_ptr_bin_stage2[AW-1:0] == rd_ptr_bin_sync_stage2[AW-1:0]) && 
                         (wr_ptr_bin_stage2[AW] != rd_ptr_bin_sync_stage2[AW]);
            // Stage 2 register
            full_stage2 <= full_stage1;
        end
    end
    
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            empty_stage1 <= 1; // Empty at reset
            empty_stage2 <= 1; // Empty at reset
        end else begin
            // Stage 1 calculation
            empty_stage1 <= (rd_ptr_bin_stage2[AW:0] == wr_ptr_bin_sync_stage2[AW:0]);
            // Stage 2 register
            empty_stage2 <= empty_stage1;
        end
    end
    
    // Final status signals
    assign full = full_stage2;
    assign empty = empty_stage2;
    
endmodule