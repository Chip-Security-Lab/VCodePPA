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

    // Write pipeline registers
    reg wr_en_stage1, wr_en_stage2;
    reg [WIDTH-1:0] wr_data_stage1, wr_data_stage2;
    reg [$clog2(DEPTH)-1:0] wr_addr_stage1, wr_addr_stage2;
    reg wr_valid_stage1, wr_valid_stage2;

    // Read pipeline registers
    reg rd_en_stage1, rd_en_stage2;
    reg [$clog2(DEPTH)-1:0] rd_addr_stage1, rd_addr_stage2;
    reg rd_valid_stage1, rd_valid_stage2;
    reg [WIDTH-1:0] rd_data_stage1;

    // Gray code conversion function
    function [$clog2(DEPTH):0] bin2gray(input [$clog2(DEPTH):0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Synchronize read pointer to write domain
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // Write stage 1: Address generation and validation
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en_stage1 <= 0;
            wr_data_stage1 <= 0;
            wr_addr_stage1 <= 0;
            wr_valid_stage1 <= 0;
        end else begin
            wr_en_stage1 <= wr_en;
            wr_data_stage1 <= wr_data;
            wr_addr_stage1 <= wr_ptr_bin[$clog2(DEPTH)-1:0];
            wr_valid_stage1 <= wr_en && !wr_full;
        end
    end

    // Write stage 2: Memory write and pointer update
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en_stage2 <= 0;
            wr_data_stage2 <= 0;
            wr_addr_stage2 <= 0;
            wr_valid_stage2 <= 0;
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else begin
            wr_en_stage2 <= wr_en_stage1;
            wr_data_stage2 <= wr_data_stage1;
            wr_addr_stage2 <= wr_addr_stage1;
            wr_valid_stage2 <= wr_valid_stage1;

            if (wr_valid_stage2) begin
                mem[wr_addr_stage2] <= wr_data_stage2;
                wr_ptr_bin <= wr_ptr_bin + 1;
                wr_ptr_gray <= bin2gray(wr_ptr_bin + 1);
            end
        end
    end

    // Read stage 1: Address generation and validation
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en_stage1 <= 0;
            rd_addr_stage1 <= 0;
            rd_valid_stage1 <= 0;
        end else begin
            rd_en_stage1 <= rd_en;
            rd_addr_stage1 <= rd_ptr_bin[$clog2(DEPTH)-1:0];
            rd_valid_stage1 <= rd_en && !rd_empty;
        end
    end

    // Read stage 2: Memory read
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en_stage2 <= 0;
            rd_addr_stage2 <= 0;
            rd_valid_stage2 <= 0;
            rd_data_stage1 <= 0;
        end else begin
            rd_en_stage2 <= rd_en_stage1;
            rd_addr_stage2 <= rd_addr_stage1;
            rd_valid_stage2 <= rd_valid_stage1;

            if (rd_valid_stage1) begin
                rd_data_stage1 <= mem[rd_addr_stage1];
            end
        end
    end

    // Read stage 3: Output and pointer update
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data <= 0;
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end else begin
            if (rd_valid_stage2) begin
                rd_data <= rd_data_stage1;
                rd_ptr_bin <= rd_ptr_bin + 1;
                rd_ptr_gray <= bin2gray(rd_ptr_bin + 1);
            end
        end
    end

    // Full flag calculation
    reg [$clog2(DEPTH):0] wr_ptr_next;
    reg full_pre;

    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_next <= 0;
            full_pre <= 0;
            wr_full <= 0;
        end else begin
            wr_ptr_next <= wr_ptr_bin + 1;
            full_pre <= (wr_ptr_next[$clog2(DEPTH)] != rd_ptr_gray_sync2[$clog2(DEPTH)]) &&
                        (wr_ptr_next[$clog2(DEPTH)-1] != rd_ptr_gray_sync2[$clog2(DEPTH)-1]) &&
                        (wr_ptr_next[$clog2(DEPTH)-2:0] == rd_ptr_gray_sync2[$clog2(DEPTH)-2:0]);
            wr_full <= full_pre;
        end
    end

    // Empty flag calculation
    reg empty_pre;

    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            empty_pre <= 1;
            rd_empty <= 1;
        end else begin
            empty_pre <= (rd_ptr_gray == wr_ptr_gray_sync1);
            rd_empty <= empty_pre;
        end
    end
endmodule