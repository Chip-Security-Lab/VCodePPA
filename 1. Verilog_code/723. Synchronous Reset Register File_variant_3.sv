//SystemVerilog
module sync_reset_regfile #(
    parameter WIDTH = 32,
    parameter DEPTH = 32,
    parameter ADDR_BITS = $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   sync_reset,   // Synchronous reset
    input  wire                   write_enable,
    input  wire [ADDR_BITS-1:0]   write_addr,
    input  wire [WIDTH-1:0]       write_data,
    input  wire [ADDR_BITS-1:0]   read_addr,
    output wire [WIDTH-1:0]       read_data
);
    // Internal signals for connecting submodules
    wire [WIDTH-1:0] memory_read_data;
    wire memory_write_en;
    wire [ADDR_BITS-1:0] memory_write_addr;
    wire [WIDTH-1:0] memory_write_data;
    
    // Control unit handles write enable and reset logic
    control_unit #(
        .WIDTH(WIDTH),
        .ADDR_BITS(ADDR_BITS)
    ) u_control (
        .clk          (clk),
        .sync_reset   (sync_reset),
        .write_enable (write_enable),
        .write_addr   (write_addr),
        .write_data   (write_data),
        .memory_write_en   (memory_write_en),
        .memory_write_addr (memory_write_addr),
        .memory_write_data (memory_write_data)
    );
    
    // Memory storage unit handles data storage and access
    memory_unit #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .ADDR_BITS(ADDR_BITS)
    ) u_memory (
        .clk          (clk),
        .sync_reset   (sync_reset),
        .write_en     (memory_write_en),
        .write_addr   (memory_write_addr),
        .write_data   (memory_write_data),
        .read_addr    (read_addr),
        .read_data    (memory_read_data)
    );
    
    // Output interface handles data output
    output_interface #(
        .WIDTH(WIDTH)
    ) u_output (
        .memory_data  (memory_read_data),
        .read_data    (read_data)
    );
    
endmodule

// Control unit handles write control logic
module control_unit #(
    parameter WIDTH = 32,
    parameter ADDR_BITS = 5
)(
    input  wire                   clk,
    input  wire                   sync_reset,
    input  wire                   write_enable,
    input  wire [ADDR_BITS-1:0]   write_addr,
    input  wire [WIDTH-1:0]       write_data,
    output reg                    memory_write_en,
    output reg  [ADDR_BITS-1:0]   memory_write_addr,
    output reg  [WIDTH-1:0]       memory_write_data
);
    // Process control signals
    always @(posedge clk) begin
        if (sync_reset) begin
            memory_write_en <= 1'b0;
            memory_write_addr <= {ADDR_BITS{1'b0}};
            memory_write_data <= {WIDTH{1'b0}};
        end
        else begin
            memory_write_en <= write_enable;
            memory_write_addr <= write_addr;
            memory_write_data <= write_data;
        end
    end
endmodule

// Memory unit handles storage and reset operations
module memory_unit #(
    parameter WIDTH = 32,
    parameter DEPTH = 32,
    parameter ADDR_BITS = $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   sync_reset,
    input  wire                   write_en,
    input  wire [ADDR_BITS-1:0]   write_addr,
    input  wire [WIDTH-1:0]       write_data,
    input  wire [ADDR_BITS-1:0]   read_addr,
    output wire [WIDTH-1:0]       read_data
);
    // Memory storage - dual port implementation
    reg [WIDTH-1:0] memory_array [0:DEPTH-1];
    
    // Read operation (combinational)
    assign read_data = memory_array[read_addr];
    
    // Reset and write operation with optimized implementation
    // Using block-specific reset to reduce fan-out
    integer i;
    always @(posedge clk) begin
        if (sync_reset) begin
            // Reset all registers synchronously with unrolled loop for better synthesis
            for (i = 0; i < DEPTH; i = i + 1) begin
                memory_array[i] <= {WIDTH{1'b0}};
            end
        end
        else if (write_en) begin
            memory_array[write_addr] <= write_data;
        end
    end
endmodule

// Output interface handles data output and can be extended for additional functionality
module output_interface #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0]       memory_data,
    output wire [WIDTH-1:0]       read_data
);
    // Direct assignment for now, but this module could be extended
    // to include output registers, error checking, or other functionality
    assign read_data = memory_data;
endmodule