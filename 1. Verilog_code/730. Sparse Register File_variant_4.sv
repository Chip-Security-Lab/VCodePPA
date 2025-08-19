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
    
    // Internal signals for address decoding
    reg [3:0] read_index;
    reg [3:0] write_index;
    reg write_addr_valid;
    
    // Address mapping function - translates full address to implemented register index
    function automatic [3:0] get_reg_index;
        input [ADDR_WIDTH-1:0] addr;
        begin
            // Only addresses that are multiples of 16 are implemented
            if ((addr & 8'h0F) == 8'h00 && addr < 16*IMPLEMENTED_REGS) begin
                get_reg_index = addr[7:4]; // Upper 4 bits form the index
            end
            else begin
                get_reg_index = 4'hF; // Invalid index
            end
        end
    endfunction
    
    // Function to check if address is valid
    function automatic is_valid_addr;
        input [ADDR_WIDTH-1:0] addr;
        begin
            is_valid_addr = ((addr & 8'h0F) == 8'h00) && (addr < 16*IMPLEMENTED_REGS);
        end
    endfunction
    
    // Address validation for read port
    always @(*) begin
        addr_valid = is_valid_addr(read_addr);
        read_index = get_reg_index(read_addr);
    end
    
    // Read data selection based on address validity
    always @(*) begin
        if (addr_valid) begin
            read_data = sparse_regs[read_index];
        end
        else begin
            read_data = {DATA_WIDTH{1'b0}};  // Return zeros for invalid addresses
        end
    end
    
    // Write address validation
    always @(*) begin
        write_addr_valid = is_valid_addr(write_addr);
        write_index = get_reg_index(write_addr);
    end
    
    // Register reset operation
    integer i;
    always @(negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < IMPLEMENTED_REGS; i = i + 1) begin
                sparse_regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end
    end
    
    // Write operation
    always @(posedge clk) begin
        if (rst_n && write_en && write_addr_valid) begin
            sparse_regs[write_index] <= write_data;
        end
    end
endmodule