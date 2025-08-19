//SystemVerilog
module sparse_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8,     // Full address width
    parameter IMPLEMENTED_REGS = 16  // Only some addresses are implemented
)(
    input  wire                   clk,
    input  wire                   rst_n,
    
    // Write port
    input  wire                   write_en,
    input  wire [ADDR_WIDTH-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]  write_data,
    
    // Read port
    input  wire [ADDR_WIDTH-1:0]  read_addr,
    output reg  [DATA_WIDTH-1:0]  read_data,
    output reg                    addr_valid    // Indicates if the address is implemented
);
    // Sparse storage - only implemented registers are stored
    reg [DATA_WIDTH-1:0] sparse_regs [0:IMPLEMENTED_REGS-1];
    
    // Optimized functions for address validation and mapping
    wire [3:0] read_index = read_addr[7:4];
    wire [3:0] write_index = write_addr[7:4];
    wire read_addr_valid = (read_addr[3:0] == 4'b0000) && (read_index < IMPLEMENTED_REGS);
    wire write_addr_valid = (write_addr[3:0] == 4'b0000) && (write_index < IMPLEMENTED_REGS);
    
    // Optimized read operation with address validation
    always @(*) begin
        addr_valid = read_addr_valid;
        read_data = addr_valid ? sparse_regs[read_index] : {DATA_WIDTH{1'b0}};
    end
    
    // Optimized write operation
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers in parallel
            for (i = 0; i < IMPLEMENTED_REGS; i = i + 1) begin
                sparse_regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (write_en && write_addr_valid) begin
            sparse_regs[write_index] <= write_data;
        end
    end
endmodule