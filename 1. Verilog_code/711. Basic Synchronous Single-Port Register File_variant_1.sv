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

    // Memory array with registered output
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] rdata_reg;
    
    // Address pipeline register
    reg [ADDR_WIDTH-1:0] addr_reg;
    
    // Write data pipeline register
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg we_reg;
    
    // First pipeline stage - register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= {ADDR_WIDTH{1'b0}};
            wdata_reg <= {DATA_WIDTH{1'b0}};
            we_reg <= 1'b0;
        end else begin
            addr_reg <= addr;
            wdata_reg <= wdata;
            we_reg <= we;
        end
    end
    
    // Memory array initialization and write operation
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (we_reg) begin
            mem[addr_reg] <= wdata_reg;
        end
    end
    
    // Read operation with registered output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            rdata_reg <= mem[addr_reg];
        end
    end
    
    // Output assignment
    assign rdata = rdata_reg;
    
endmodule