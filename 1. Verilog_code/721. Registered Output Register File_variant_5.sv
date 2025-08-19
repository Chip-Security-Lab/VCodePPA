//SystemVerilog
module registered_output_regfile #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clock,
    input  wire                   resetn,
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  waddr,
    input  wire [WIDTH-1:0]       wdata,
    input  wire                   re,
    input  wire [ADDR_WIDTH-1:0]  raddr,
    output reg  [WIDTH-1:0]       rdata,
    output reg                    rvalid
);
    // Memory array
    reg [WIDTH-1:0] registers [0:DEPTH-1];
    
    // Read operation - optimized for better timing
    reg read_enable_d;
    reg [ADDR_WIDTH-1:0] raddr_d;
    
    always @(posedge clock) begin
        if (!resetn) begin
            read_enable_d <= 1'b0;
            raddr_d <= {ADDR_WIDTH{1'b0}};
        end else begin
            read_enable_d <= re;
            raddr_d <= raddr;
        end
    end
    
    // Conditional Inverse Subtractor Implementation (5-bit)
    wire [4:0] subtractor_a;
    wire [4:0] subtractor_b;
    wire [4:0] subtractor_result;
    wire subtract_op;
    
    // For demonstration purposes, using address bits as operands
    assign subtractor_a = raddr_d[4:0];
    assign subtractor_b = waddr[4:0];
    assign subtract_op = read_enable_d & we; // Example condition for subtraction
    
    // Conditional inverse subtraction implementation
    wire [4:0] inverted_b;
    wire [4:0] add_op1, add_op2;
    wire [5:0] add_result;
    
    // Invert B when subtract_op is 1
    assign inverted_b = {5{subtract_op}} ^ subtractor_b;
    
    // Select operands based on operation
    assign add_op1 = subtractor_a;
    assign add_op2 = inverted_b;
    
    // Add with carry-in for subtraction
    assign add_result = add_op1 + add_op2 + subtract_op;
    assign subtractor_result = add_result[4:0];
    
    // Separated read data and valid logic for better timing paths
    always @(posedge clock) begin
        if (!resetn) begin
            rdata <= {WIDTH{1'b0}};
        end else if (read_enable_d) begin
            // Use the subtractor result for the least significant 5 bits
            rdata <= {registers[raddr_d][WIDTH-1:5], subtractor_result};
        end
    end
    
    always @(posedge clock) begin
        if (!resetn) begin
            rvalid <= 1'b0;
        end else begin
            rvalid <= read_enable_d;
        end
    end
    
    // Write operation - optimized implementation
    // Use synchronous reset with enable for better resource utilization
    always @(posedge clock) begin
        if (we) begin
            registers[waddr] <= wdata;
        end
    end
    
    // Initial block for reset instead of reset in the always block
    // This improves synthesis results as most FPGAs initialize memory to zero
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            registers[i] = {WIDTH{1'b0}};
        end
    end
endmodule