//SystemVerilog
module CircularBuffer #(
    parameter DEPTH = 8,
    parameter ADDR_WIDTH = 3
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire                  data_in,
    output reg                   data_out
);

// Write and Read Pointer Registers
reg  [ADDR_WIDTH-1:0]        wr_ptr, rd_ptr;

// Pipeline Stage 1 Registers: Merge input capture and memory access
reg                          wr_en_stage1, rd_en_stage1;
reg                          data_in_stage1;
reg  [ADDR_WIDTH-1:0]        wr_ptr_stage1, rd_ptr_stage1;
reg                          data_out_stage1;

// Circular Buffer Memory
reg  [DEPTH-1:0]             mem;

// Write and Read Pointer Logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr <= {ADDR_WIDTH{1'b0}};
        rd_ptr <= {ADDR_WIDTH{1'b0}};
    end else begin
        wr_ptr <= wr_ptr + (wr_en ? 1'b1 : 1'b0);
        rd_ptr <= rd_ptr + (rd_en ? 1'b1 : 1'b0);
    end
end

// Pipeline Stage 1: Input, pointer, memory access, and data output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_en_stage1    <= 1'b0;
        rd_en_stage1    <= 1'b0;
        data_in_stage1  <= 1'b0;
        wr_ptr_stage1   <= {ADDR_WIDTH{1'b0}};
        rd_ptr_stage1   <= {ADDR_WIDTH{1'b0}};
        data_out_stage1 <= 1'b0;
    end else begin
        wr_en_stage1    <= wr_en;
        rd_en_stage1    <= rd_en;
        data_in_stage1  <= data_in;
        wr_ptr_stage1   <= wr_ptr;
        rd_ptr_stage1   <= rd_ptr;
        if (rd_en) begin
            data_out_stage1 <= mem[rd_ptr];
        end else begin
            data_out_stage1 <= data_out_stage1;
        end
    end
end

// Memory Write Operation (merged in Stage 1)
always @(posedge clk) begin
    if (wr_en_stage1) begin
        mem[wr_ptr_stage1] <= data_in_stage1;
    end
end

// Output Register (Stage 2)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 1'b0;
    end else begin
        data_out <= data_out_stage1;
    end
end

endmodule