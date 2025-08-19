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
    reg [AW:0] wr_ptr_bin_stage1=0, wr_ptr_bin_stage2=0, wr_ptr_bin_stage3=0;
    reg [AW:0] wr_ptr_gray_stage1=0, wr_ptr_gray_stage2=0, wr_ptr_gray_stage3=0;
    
    // Pipeline stage registers for read path
    reg rd_en_stage1, rd_en_stage2;
    reg [AW:0] rd_ptr_bin_stage1=0, rd_ptr_bin_stage2=0, rd_ptr_bin_stage3=0;
    reg [AW:0] rd_ptr_gray_stage1=0, rd_ptr_gray_stage2=0, rd_ptr_gray_stage3=0;
    reg [DW-1:0] dout_stage1, dout_stage2;
    
    // Synchronized pointers (3-FF synchronizers for improved metastability)
    reg [AW:0] rd_ptr_gray_sync1=0, rd_ptr_gray_sync2=0, rd_ptr_gray_sync3=0;
    reg [AW:0] wr_ptr_gray_sync1=0, wr_ptr_gray_sync2=0, wr_ptr_gray_sync3=0;
    
    // Pipeline valid signals
    reg wr_valid_stage1, wr_valid_stage2, wr_valid_stage3;
    reg rd_valid_stage1, rd_valid_stage2, rd_valid_stage3;
    
    // Full/empty calculation pipeline registers
    reg [AW:0] rd_ptr_bin_sync_stage1, rd_ptr_bin_sync_stage2;
    reg [AW:0] wr_ptr_bin_sync_stage1, wr_ptr_bin_sync_stage2;
    reg full_stage1, full_stage2;
    reg empty_stage1, empty_stage2;
    
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
    
    // Write Stage 1: Input capture
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en_stage1 <= 0;
            din_stage1 <= 0;
        end else begin
            wr_en_stage1 <= wr_en;
            din_stage1 <= din;
        end
    end
    
    // Write Stage 1: Valid signal generation
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_valid_stage1 <= 0;
        end else begin
            wr_valid_stage1 <= wr_en && !full;
        end
    end
    
    // Write Stage 1: Pointer update
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin_stage1 <= 0;
            wr_ptr_gray_stage1 <= 0;
        end else begin
            if (wr_en && !full) begin
                wr_ptr_bin_stage1 <= wr_ptr_bin_stage3 + 1;
                wr_ptr_gray_stage1 <= bin_to_gray(wr_ptr_bin_stage3 + 1);
            end else begin
                wr_ptr_bin_stage1 <= wr_ptr_bin_stage3;
                wr_ptr_gray_stage1 <= wr_ptr_gray_stage3;
            end
        end
    end
    
    // Write Stage 2: Control signal propagation
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en_stage2 <= 0;
            din_stage2 <= 0;
            wr_valid_stage2 <= 0;
        end else begin
            wr_en_stage2 <= wr_en_stage1;
            din_stage2 <= din_stage1;
            wr_valid_stage2 <= wr_valid_stage1;
        end
    end
    
    // Write Stage 2: Pointer propagation
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin_stage2 <= 0;
            wr_ptr_gray_stage2 <= 0;
        end else begin
            wr_ptr_bin_stage2 <= wr_ptr_bin_stage1;
            wr_ptr_gray_stage2 <= wr_ptr_gray_stage1;
        end
    end
    
    // Write Stage 2: Memory write operation
    always @(posedge wr_clk) begin
        if (wr_valid_stage1) begin
            mem[wr_ptr_bin_stage3[AW-1:0]] <= din_stage1;
        end
    end
    
    // Write Stage 3: Pointer and valid signal update
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin_stage3 <= 0;
            wr_ptr_gray_stage3 <= 0;
            wr_valid_stage3 <= 0;
        end else begin
            wr_valid_stage3 <= wr_valid_stage2;
            if (wr_valid_stage2) begin
                wr_ptr_bin_stage3 <= wr_ptr_bin_stage2;
                wr_ptr_gray_stage3 <= wr_ptr_gray_stage2;
            end
        end
    end
    
    // Read Stage 1: Control signal capture
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en_stage1 <= 0;
            rd_valid_stage1 <= 0;
        end else begin
            rd_en_stage1 <= rd_en;
            rd_valid_stage1 <= rd_en && !empty;
        end
    end
    
    // Read Stage 1: Pointer update
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin_stage1 <= 0;
            rd_ptr_gray_stage1 <= 0;
        end else begin
            if (rd_en && !empty) begin
                rd_ptr_bin_stage1 <= rd_ptr_bin_stage3 + 1;
                rd_ptr_gray_stage1 <= bin_to_gray(rd_ptr_bin_stage3 + 1);
            end else begin
                rd_ptr_bin_stage1 <= rd_ptr_bin_stage3;
                rd_ptr_gray_stage1 <= rd_ptr_gray_stage3;
            end
        end
    end
    
    // Read Stage 2: Control signal propagation
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en_stage2 <= 0;
            rd_valid_stage2 <= 0;
        end else begin
            rd_en_stage2 <= rd_en_stage1;
            rd_valid_stage2 <= rd_valid_stage1;
        end
    end
    
    // Read Stage 2: Pointer propagation
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin_stage2 <= 0;
            rd_ptr_gray_stage2 <= 0;
        end else begin
            rd_ptr_bin_stage2 <= rd_ptr_bin_stage1;
            rd_ptr_gray_stage2 <= rd_ptr_gray_stage1;
        end
    end
    
    // Read Stage 2: Memory read operation
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage1 <= 0;
        end else if (rd_valid_stage1) begin
            dout_stage1 <= mem[rd_ptr_bin_stage3[AW-1:0]];
        end
    end
    
    // Read Stage 3: Valid signal update
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_valid_stage3 <= 0;
        end else begin
            rd_valid_stage3 <= rd_valid_stage2;
        end
    end
    
    // Read Stage 3: Pointer update
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin_stage3 <= 0;
            rd_ptr_gray_stage3 <= 0;
        end else if (rd_valid_stage2) begin
            rd_ptr_bin_stage3 <= rd_ptr_bin_stage2;
            rd_ptr_gray_stage3 <= rd_ptr_gray_stage2;
        end
    end
    
    // Read Stage 3: Data output propagation
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage2 <= 0;
        end else begin
            dout_stage2 <= dout_stage1;
        end
    end
    
    // Write pointer synchronizer stage 1
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray_stage3;
        end
    end
    
    // Write pointer synchronizer stages 2-3
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync2 <= 0;
            wr_ptr_gray_sync3 <= 0;
        end else begin
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
            wr_ptr_gray_sync3 <= wr_ptr_gray_sync2;
        end
    end
    
    // Read pointer synchronizer stage 1
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync1 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray_stage3;
        end
    end
    
    // Read pointer synchronizer stages 2-3
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync2 <= 0;
            rd_ptr_gray_sync3 <= 0;
        end else begin
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
            rd_ptr_gray_sync3 <= rd_ptr_gray_sync2;
        end
    end
    
    // Empty flag calculation stage 1: Gray to binary conversion
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin_sync_stage1 <= 0;
        end else begin
            wr_ptr_bin_sync_stage1 <= gray_to_bin(wr_ptr_gray_sync3);
        end
    end
    
    // Empty flag calculation stage 2: Binary comparison
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin_sync_stage2 <= 0;
            empty_stage1 <= 1;
        end else begin
            wr_ptr_bin_sync_stage2 <= wr_ptr_bin_sync_stage1;
            empty_stage1 <= (rd_ptr_bin_stage3 == wr_ptr_bin_sync_stage1);
        end
    end
    
    // Empty flag final stage
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            empty_stage2 <= 1;
        end else begin
            empty_stage2 <= empty_stage1;
        end
    end
    
    // Full flag calculation stage 1: Gray to binary conversion
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin_sync_stage1 <= 0;
        end else begin
            rd_ptr_bin_sync_stage1 <= gray_to_bin(rd_ptr_gray_sync3);
        end
    end
    
    // Full flag calculation stage 2: Binary comparison
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin_sync_stage2 <= 0;
            full_stage1 <= 0;
        end else begin
            rd_ptr_bin_sync_stage2 <= rd_ptr_bin_sync_stage1;
            full_stage1 <= (wr_ptr_bin_stage3[AW-1:0] == rd_ptr_bin_sync_stage1[AW-1:0]) && 
                         (wr_ptr_bin_stage3[AW] != rd_ptr_bin_sync_stage1[AW]);
        end
    end
    
    // Full flag final stage
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            full_stage2 <= 0;
        end else begin
            full_stage2 <= full_stage1;
        end
    end
    
    // Output assignments
    assign dout = dout_stage2;
    assign full = full_stage2;
    assign empty = empty_stage2;
    
endmodule