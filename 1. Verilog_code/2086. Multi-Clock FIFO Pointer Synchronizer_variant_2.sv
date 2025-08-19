//SystemVerilog
module fifo_ptr_sync #(
    parameter ADDR_WIDTH = 5
) (
    input  wire                   wr_clk,
    input  wire                   rd_clk,
    input  wire                   reset,
    input  wire                   write,
    input  wire                   read,
    output wire                   full,
    output wire                   empty,
    output reg  [ADDR_WIDTH-1:0]  wr_addr,
    output reg  [ADDR_WIDTH-1:0]  rd_addr
);

// Binary and Gray code pointers
reg  [ADDR_WIDTH:0] wr_ptr_bin_reg;
reg  [ADDR_WIDTH:0] wr_ptr_gray_reg;
reg  [ADDR_WIDTH:0] rd_ptr_bin_reg;
reg  [ADDR_WIDTH:0] rd_ptr_gray_reg;
reg  [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
reg  [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;

// Pipeline registers for full/empty flags
reg                 full_pipe, empty_pipe;

// Next value wires
wire [ADDR_WIDTH:0] wr_ptr_bin_next;
wire [ADDR_WIDTH:0] wr_ptr_gray_next;
wire [ADDR_WIDTH:0] rd_ptr_bin_next;
wire [ADDR_WIDTH:0] rd_ptr_gray_next;

// Delayed signals for retiming
reg  [ADDR_WIDTH:0] wr_ptr_gray_reg_d1;
reg  [ADDR_WIDTH:0] rd_ptr_gray_reg_d1;
reg                 full_pipe_d1, empty_pipe_d1;
reg  [ADDR_WIDTH:0] wr_ptr_bin_reg_d1;
reg  [ADDR_WIDTH:0] rd_ptr_bin_reg_d1;

// Binary counter increments
assign wr_ptr_bin_next  = wr_ptr_bin_reg + (write & ~full_pipe);
assign rd_ptr_bin_next  = rd_ptr_bin_reg + (read & ~empty_pipe);

// Binary to Gray conversion
assign wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;
assign rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

// Write pointer: binary and Gray update after combinational logic
always @(posedge wr_clk or posedge reset) begin
    if (reset) begin
        wr_ptr_bin_reg  <= {ADDR_WIDTH+1{1'b0}};
        wr_ptr_gray_reg <= {ADDR_WIDTH+1{1'b0}};
        wr_ptr_bin_reg_d1  <= {ADDR_WIDTH+1{1'b0}};
        wr_ptr_gray_reg_d1 <= {ADDR_WIDTH+1{1'b0}};
    end else begin
        wr_ptr_bin_reg  <= wr_ptr_bin_next;
        wr_ptr_gray_reg <= wr_ptr_gray_next;
        wr_ptr_bin_reg_d1  <= wr_ptr_bin_reg;
        wr_ptr_gray_reg_d1 <= wr_ptr_gray_reg;
    end
end

// Read pointer: binary and Gray update after combinational logic
always @(posedge rd_clk or posedge reset) begin
    if (reset) begin
        rd_ptr_bin_reg  <= {ADDR_WIDTH+1{1'b0}};
        rd_ptr_gray_reg <= {ADDR_WIDTH+1{1'b0}};
        rd_ptr_bin_reg_d1  <= {ADDR_WIDTH+1{1'b0}};
        rd_ptr_gray_reg_d1 <= {ADDR_WIDTH+1{1'b0}};
    end else begin
        rd_ptr_bin_reg  <= rd_ptr_bin_next;
        rd_ptr_gray_reg <= rd_ptr_gray_next;
        rd_ptr_bin_reg_d1  <= rd_ptr_bin_reg;
        rd_ptr_gray_reg_d1 <= rd_ptr_gray_reg;
    end
end

// Synchronize pointers (write pointer into read clock, read pointer into write clock)
always @(posedge rd_clk or posedge reset) begin
    if (reset) begin
        wr_ptr_gray_sync1 <= {ADDR_WIDTH+1{1'b0}};
        wr_ptr_gray_sync2 <= {ADDR_WIDTH+1{1'b0}};
    end else begin
        wr_ptr_gray_sync1 <= wr_ptr_gray_reg_d1;
        wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
end

always @(posedge wr_clk or posedge reset) begin
    if (reset) begin
        rd_ptr_gray_sync1 <= {ADDR_WIDTH+1{1'b0}};
        rd_ptr_gray_sync2 <= {ADDR_WIDTH+1{1'b0}};
    end else begin
        rd_ptr_gray_sync1 <= rd_ptr_gray_reg_d1;
        rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
end

// Full flag pipeline after combinational logic
always @(posedge wr_clk or posedge reset) begin
    if (reset) begin
        full_pipe    <= 1'b0;
        full_pipe_d1 <= 1'b0;
    end else begin
        full_pipe    <= (wr_ptr_gray_next == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
        full_pipe_d1 <= full_pipe;
    end
end

// Empty flag pipeline after combinational logic
always @(posedge rd_clk or posedge reset) begin
    if (reset) begin
        empty_pipe    <= 1'b1;
        empty_pipe_d1 <= 1'b1;
    end else begin
        empty_pipe    <= (rd_ptr_gray_next == wr_ptr_gray_sync2);
        empty_pipe_d1 <= empty_pipe;
    end
end

// Output assignments
assign full  = full_pipe_d1;
assign empty = empty_pipe_d1;

// Extract memory addresses, pipeline for timing alignment
always @(posedge wr_clk or posedge reset) begin
    if (reset) begin
        wr_addr <= {ADDR_WIDTH{1'b0}};
    end else begin
        wr_addr <= wr_ptr_bin_reg_d1[ADDR_WIDTH-1:0];
    end
end

always @(posedge rd_clk or posedge reset) begin
    if (reset) begin
        rd_addr <= {ADDR_WIDTH{1'b0}};
    end else begin
        rd_addr <= rd_ptr_bin_reg_d1[ADDR_WIDTH-1:0];
    end
end

endmodule