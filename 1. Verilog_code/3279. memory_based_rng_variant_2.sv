//SystemVerilog
// SystemVerilog
// Top-level module for hierarchical memory-based RNG design
module memory_based_rng #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [3:0]        addr_seed,
    output wire [WIDTH-1:0]  random_val
);

    // Internal signals
    wire [WIDTH-1:0] mem_read_data;
    wire [WIDTH-1:0] mem_write_data;
    wire [3:0]       mem_addr_read;
    wire [3:0]       mem_addr_write;
    wire             mem_write_en;
    wire [3:0]       addr_ptr_next;
    wire [3:0]       addr_ptr_curr;
    wire [WIDTH-1:0] last_val;
    wire [1:0]       mem_read_lsb;
    wire [3:0]       addr_ptr_inc;

    // Address pointer and last value register logic
    rng_ctrl #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) u_rng_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .addr_seed      (addr_seed),
        .mem_read_data  (mem_read_data),
        .addr_ptr_curr  (addr_ptr_curr),
        .addr_ptr_next  (addr_ptr_next),
        .last_val       (last_val),
        .mem_read_lsb   (mem_read_lsb),
        .addr_ptr_inc   (addr_ptr_inc)
    );

    // RNG combinational datapath (XOR and address increment logic)
    rng_datapath #(
        .WIDTH(WIDTH)
    ) u_rng_datapath (
        .mem_read_data  (mem_read_data),
        .last_val       (last_val),
        .mem_write_data (mem_write_data),
        .mem_read_lsb   (mem_read_lsb),
        .addr_ptr_inc   (addr_ptr_inc)
    );

    // Memory module for RNG state storage
    rng_mem #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) u_rng_mem (
        .clk           (clk),
        .rst_n         (rst_n),
        .init_seed     (addr_seed),
        .wr_en         (mem_write_en),
        .wr_addr       (mem_addr_write),
        .wr_data       (mem_write_data),
        .rd_addr       (mem_addr_read),
        .rd_data       (mem_read_data),
        .random_val    (random_val)
    );

    // Write enable only during normal operation (not during reset)
    assign mem_write_en   = rst_n;
    assign mem_addr_read  = addr_ptr_curr;
    assign mem_addr_write = addr_ptr_curr;

endmodule

//-----------------------------------------------------------------------------
// rng_ctrl: RNG control logic (address pointer and last value registers)
//-----------------------------------------------------------------------------
module rng_ctrl #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [3:0]        addr_seed,
    input  wire [WIDTH-1:0]  mem_read_data,
    output reg  [3:0]        addr_ptr_curr,
    output reg  [3:0]        addr_ptr_next,
    output reg  [WIDTH-1:0]  last_val,
    output wire [1:0]        mem_read_lsb,
    output wire [3:0]        addr_ptr_inc
);
    // Extract LSBs from memory read value
    assign mem_read_lsb = mem_read_data[1:0];
    assign addr_ptr_inc = {2'b00, mem_read_lsb} + 4'd1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_ptr_curr <= addr_seed;
            last_val      <= {WIDTH{1'b0}};
            addr_ptr_next <= addr_seed;
        end else begin
            last_val      <= mem_read_data;
            addr_ptr_curr <= addr_ptr_next;
            addr_ptr_next <= addr_ptr_next + addr_ptr_inc;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// rng_datapath: RNG combinational datapath (XOR and address increment logic)
//-----------------------------------------------------------------------------
module rng_datapath #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] mem_read_data,
    input  wire [WIDTH-1:0] last_val,
    output wire [WIDTH-1:0] mem_write_data,
    output wire [1:0]       mem_read_lsb,
    output wire [3:0]       addr_ptr_inc
);
    // XOR operation for RNG update
    assign mem_write_data = mem_read_data ^ (last_val << 1);

    // Provide LSB and increment value for address pointer logic
    assign mem_read_lsb = mem_read_data[1:0];
    assign addr_ptr_inc = {2'b00, mem_read_lsb} + 4'd1;
endmodule

//-----------------------------------------------------------------------------
// rng_mem: Parameterized memory module for RNG state storage
//-----------------------------------------------------------------------------
module rng_mem #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [3:0]        init_seed,
    input  wire              wr_en,
    input  wire [3:0]        wr_addr,
    input  wire [WIDTH-1:0]  wr_data,
    input  wire [3:0]        rd_addr,
    output wire [WIDTH-1:0]  rd_data,
    output wire [WIDTH-1:0]  random_val
);
    // Internal memory
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    integer i;

    // Synchronous write and reset logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= (i * 7) + 11;
        end else if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // Asynchronous read for current address pointer
    assign rd_data    = mem[rd_addr];
    assign random_val = mem[rd_addr];
endmodule