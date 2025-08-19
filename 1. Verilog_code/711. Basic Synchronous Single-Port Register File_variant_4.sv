//SystemVerilog
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

    // Memory array with registered outputs
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] rdata_reg;
    
    // Combined pipeline stage for better timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_reg <= {DATA_WIDTH{1'b0}};
            for (int i = 0; i < DEPTH; i++) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            // Read operation
            rdata_reg <= mem[addr];
            
            // Write operation
            if (we) begin
                mem[addr] <= wdata;
            end
        end
    end
    
    // Output assignment
    assign rdata = rdata_reg;
    
endmodule