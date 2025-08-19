//SystemVerilog
module CircularBuffer #(
    parameter DEPTH = 8,
    parameter ADDR_WIDTH = 3
)(
    input wire                  clk,
    input wire                  wr_en,
    input wire                  rd_en,
    input wire                  data_in,
    output reg                  data_out
);

    // Internal buffer memory
    reg [DEPTH-1:0]             buffer_mem;

    // Write and read pointer
    reg [ADDR_WIDTH-1:0]        wr_ptr, wr_ptr_next;
    reg [ADDR_WIDTH-1:0]        rd_ptr, rd_ptr_next;

    // Write enable and data_in after logic
    wire                        wr_en_delayed;
    wire                        data_in_delayed;

    // Pipeline for memory read
    reg [DEPTH-1:0]             mem_snapshot_stage0, mem_snapshot_stage1;
    reg [ADDR_WIDTH-1:0]        rd_ptr_latch_stage0, rd_ptr_latch_stage1;
    reg                         mem_read_stage0, mem_read_stage1;

    // Data out pipeline
    reg                         data_out_stage0, data_out_stage1;

    // Pipeline register: Write address/data and pointer update logic
    always @(posedge clk) begin
        wr_ptr <= wr_ptr_next;
    end

    always @(*) begin
        wr_ptr_next = wr_ptr + (wr_en ? 1'b1 : 1'b0);
    end

    // Pipeline register: Read address and pointer update logic
    always @(posedge clk) begin
        rd_ptr <= rd_ptr_next;
    end

    always @(*) begin
        rd_ptr_next = rd_ptr + (rd_en ? 1'b1 : 1'b0);
    end

    // Move input-stage registers after combination logic (forward retiming)
    assign wr_en_delayed   = wr_en;
    assign data_in_delayed = data_in;

    // Memory write
    always @(posedge clk) begin
        if (wr_en_delayed)
            buffer_mem[wr_ptr] <= data_in_delayed;
    end

    // Pipeline register: Memory read snapshot and address latch
    always @(posedge clk) begin
        mem_snapshot_stage0    <= buffer_mem;
        rd_ptr_latch_stage0    <= rd_ptr;
        mem_snapshot_stage1    <= mem_snapshot_stage0;
        rd_ptr_latch_stage1    <= rd_ptr_latch_stage0;
        mem_read_stage0        <= rd_en;
        mem_read_stage1        <= mem_read_stage0;
    end

    // Pipeline register: Data out
    always @(posedge clk) begin
        if (mem_read_stage1)
            data_out_stage0 <= mem_snapshot_stage1[rd_ptr_latch_stage1];
        data_out_stage1 <= data_out_stage0;
    end

    // Output register
    always @(posedge clk) begin
        data_out <= data_out_stage1;
    end

    // Initial block for simulation
    initial begin
        wr_ptr                = 0;
        wr_ptr_next           = 0;
        rd_ptr                = 0;
        rd_ptr_next           = 0;
        mem_snapshot_stage0   = 0;
        mem_snapshot_stage1   = 0;
        rd_ptr_latch_stage0   = 0;
        rd_ptr_latch_stage1   = 0;
        mem_read_stage0       = 0;
        mem_read_stage1       = 0;
        data_out_stage0       = 0;
        data_out_stage1       = 0;
        buffer_mem            = 0;
        data_out              = 0;
    end

endmodule