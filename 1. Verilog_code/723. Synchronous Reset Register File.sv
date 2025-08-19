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
    // Memory storage
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    
    // Read operation (combinational)
    assign read_data = memory[read_addr];
    
    // Write operation with synchronous reset
    integer i;
    always @(posedge clk) begin
        if (sync_reset) begin
            // Reset all registers synchronously
            for (i = 0; i < DEPTH; i = i + 1) begin
                memory[i] <= {WIDTH{1'b0}};
            end
        end
        else if (write_enable) begin
            memory[write_addr] <= write_data;
        end
    end
endmodule