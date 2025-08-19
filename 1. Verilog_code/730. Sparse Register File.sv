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
    
    // Address mapping - translates full address to implemented register index
    // For this example, we'll implement a simple mapping where only every 16th address is implemented
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
    
    // Read operation with address validation
    always @(*) begin
        addr_valid = is_valid_addr(read_addr);
        
        if (addr_valid) begin
            read_data = sparse_regs[get_reg_index(read_addr)];
        end
        else begin
            read_data = {DATA_WIDTH{1'b0}};  // Return zeros for invalid addresses
        end
    end
    
    // Write operation
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < IMPLEMENTED_REGS; i = i + 1) begin
                sparse_regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (write_en && is_valid_addr(write_addr)) begin
            sparse_regs[get_reg_index(write_addr)] <= write_data;
        end
    end
endmodule