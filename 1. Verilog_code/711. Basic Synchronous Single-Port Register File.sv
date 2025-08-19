module basic_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  addr,
    input  wire [DATA_WIDTH-1:0]  wdata,
    output wire [DATA_WIDTH-1:0]  rdata
);
    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Read operation (combinational)
    assign rdata = mem[addr];
    
    // Write operation (sequential)
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize all registers to zero on reset
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end 
        else if (we) begin
            mem[addr] <= wdata;
        end
    end
endmodule