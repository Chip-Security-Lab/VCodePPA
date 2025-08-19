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
    
    // Intermediate signals for address validation and indexing
    wire [3:0] lower_bits;
    wire [3:0] upper_bits;
    wire addr_in_range;
    wire addr_aligned;
    wire [3:0] reg_index;
    
    // Extract address bits for cleaner conditions
    assign lower_bits = read_addr[3:0];
    assign upper_bits = read_addr[7:4];
    
    // Check if address is properly aligned (multiple of 16)
    assign addr_aligned = (lower_bits == 4'h0);
    
    // 使用借位减法器算法检查地址范围
    wire [3:0] borrow;
    wire [3:0] diff;
    
    // 实现4位借位减法器: upper_bits < IMPLEMENTED_REGS
    // 计算 upper_bits - IMPLEMENTED_REGS 的差值和借位
    // 如果最高位有借位，则表示 upper_bits < IMPLEMENTED_REGS
    assign borrow[0] = (upper_bits[0] < IMPLEMENTED_REGS[0]);
    assign diff[0] = upper_bits[0] ^ IMPLEMENTED_REGS[0] ^ borrow[0];
    
    assign borrow[1] = ((upper_bits[1] < IMPLEMENTED_REGS[1]) || 
                        (upper_bits[1] == IMPLEMENTED_REGS[1] && borrow[0]));
    assign diff[1] = upper_bits[1] ^ IMPLEMENTED_REGS[1] ^ borrow[0];
    
    assign borrow[2] = ((upper_bits[2] < IMPLEMENTED_REGS[2]) || 
                        (upper_bits[2] == IMPLEMENTED_REGS[2] && borrow[1]));
    assign diff[2] = upper_bits[2] ^ IMPLEMENTED_REGS[2] ^ borrow[1];
    
    assign borrow[3] = ((upper_bits[3] < IMPLEMENTED_REGS[3]) || 
                        (upper_bits[3] == IMPLEMENTED_REGS[3] && borrow[2]));
    assign diff[3] = upper_bits[3] ^ IMPLEMENTED_REGS[3] ^ borrow[2];
    
    // 如果最高位有借位，说明 upper_bits < IMPLEMENTED_REGS
    assign addr_in_range = borrow[3];
    
    // Combine conditions for address validation
    wire read_addr_valid;
    assign read_addr_valid = addr_aligned && addr_in_range;
    
    // Get register index from upper bits
    assign reg_index = upper_bits;
    
    // Read operation with address validation
    always @(*) begin
        addr_valid = read_addr_valid;
        
        if (addr_valid) begin
            read_data = sparse_regs[reg_index];
        end
        else begin
            read_data = {DATA_WIDTH{1'b0}};  // Return zeros for invalid addresses
        end
    end
    
    // Write address validation
    wire write_lower_bits_valid;
    wire write_upper_bits_valid;
    wire write_addr_valid;
    wire [3:0] write_reg_index;
    
    assign write_lower_bits_valid = (write_addr[3:0] == 4'h0);
    
    // 使用借位减法器算法检查写地址范围
    wire [3:0] write_borrow;
    wire [3:0] write_diff;
    wire [3:0] write_upper_bits;
    
    assign write_upper_bits = write_addr[7:4];
    
    // 实现4位借位减法器: write_upper_bits < IMPLEMENTED_REGS
    assign write_borrow[0] = (write_upper_bits[0] < IMPLEMENTED_REGS[0]);
    assign write_diff[0] = write_upper_bits[0] ^ IMPLEMENTED_REGS[0] ^ write_borrow[0];
    
    assign write_borrow[1] = ((write_upper_bits[1] < IMPLEMENTED_REGS[1]) || 
                              (write_upper_bits[1] == IMPLEMENTED_REGS[1] && write_borrow[0]));
    assign write_diff[1] = write_upper_bits[1] ^ IMPLEMENTED_REGS[1] ^ write_borrow[0];
    
    assign write_borrow[2] = ((write_upper_bits[2] < IMPLEMENTED_REGS[2]) || 
                              (write_upper_bits[2] == IMPLEMENTED_REGS[2] && write_borrow[1]));
    assign write_diff[2] = write_upper_bits[2] ^ IMPLEMENTED_REGS[2] ^ write_borrow[1];
    
    assign write_borrow[3] = ((write_upper_bits[3] < IMPLEMENTED_REGS[3]) || 
                              (write_upper_bits[3] == IMPLEMENTED_REGS[3] && write_borrow[2]));
    assign write_diff[3] = write_upper_bits[3] ^ IMPLEMENTED_REGS[3] ^ write_borrow[2];
    
    assign write_upper_bits_valid = write_borrow[3];
    assign write_addr_valid = write_lower_bits_valid && write_upper_bits_valid;
    assign write_reg_index = write_addr[7:4];
    
    // Write operation
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < IMPLEMENTED_REGS; i = i + 1) begin
                sparse_regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else begin
            if (write_en) begin
                if (write_addr_valid) begin
                    sparse_regs[write_reg_index] <= write_data;
                end
            end
        end
    end
endmodule