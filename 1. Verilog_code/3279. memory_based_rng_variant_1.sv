//SystemVerilog
// SystemVerilog
// Top-level module: Hierarchical memory-based random number generator

module memory_based_rng #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [3:0]       addr_seed,
    output wire [WIDTH-1:0] random_val
);

    // Internal signals for submodule interconnection
    wire [WIDTH-1:0] mem_out;
    wire [3:0]       pointer_out;
    wire [WIDTH-1:0] prev_val_out;

    // Submodule: Memory Initialization and Storage
    memory_storage #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) u_memory_storage (
        .clk         (clk),
        .rst_n       (rst_n),
        .init_seed   (addr_seed),
        .pointer_in  (pointer_out),
        .prev_val_in (prev_val_out),
        .mem_data    (mem_out),
        .mem_update  (mem_update),
        .mem_read    (mem_read)
    );

    // Submodule: Pointer and Previous Value Management
    pointer_prevval_ctrl #(
        .WIDTH(WIDTH)
    ) u_pointer_prevval_ctrl (
        .clk         (clk),
        .rst_n       (rst_n),
        .addr_seed   (addr_seed),
        .mem_data    (mem_out),
        .pointer     (pointer_out),
        .prev_val    (prev_val_out),
        .mem_update  (mem_update),
        .mem_read    (mem_read)
    );

    // Output assignment
    assign random_val = mem_out;

endmodule

// -----------------------------------------------------------------------------
// Submodule: Memory Storage
// Handles memory array, initialization, and update logic
// -----------------------------------------------------------------------------
module memory_storage #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [3:0]       init_seed,
    input  wire [3:0]       pointer_in,
    input  wire [WIDTH-1:0] prev_val_in,
    output reg  [WIDTH-1:0] mem_data,
    input  wire             mem_update,
    input  wire             mem_read
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    integer idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (idx = 0; idx < DEPTH; idx = idx + 1)
                mem[idx] <= idx * 7 + 11;
        end else if (mem_update) begin
            // mem[pointer_in] <= (mem[pointer_in] & ~(prev_val_in << 1)) | (~mem[pointer_in] & (prev_val_in << 1));
            mem[pointer_in] <= (mem[pointer_in] & ~(prev_val_in << 1)) | (~mem[pointer_in] & (prev_val_in << 1));
        end
    end

    always @(*) begin
        if (mem_read)
            mem_data = mem[pointer_in];
        else
            mem_data = {WIDTH{1'b0}};
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: Pointer and Previous Value Control
// Handles pointer increment logic and previous value update
// -----------------------------------------------------------------------------
module pointer_prevval_ctrl #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [3:0]       addr_seed,
    input  wire [WIDTH-1:0] mem_data,
    output reg  [3:0]       pointer,
    output reg  [WIDTH-1:0] prev_val,
    output reg              mem_update,
    output reg              mem_read
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pointer   <= addr_seed;
            prev_val  <= {WIDTH{1'b0}};
        end else begin
            prev_val  <= mem_data;
            pointer   <= pointer + mem_data[1:0] + 1'b1;
        end
    end

    always @(*) begin
        mem_update = 1'b1; // Always update memory on each clock cycle when not in reset
        mem_read   = 1'b1; // Always read memory for output
    end

endmodule