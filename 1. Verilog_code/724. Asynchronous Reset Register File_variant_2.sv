//SystemVerilog
// Top-level module
module async_reset_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   arst_n,      // Active-low asynchronous reset
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  waddr,
    input  wire [DATA_WIDTH-1:0]  wdata,
    input  wire [ADDR_WIDTH-1:0]  raddr,
    output wire [DATA_WIDTH-1:0]  rdata
);
    // Internal signals
    wire [DATA_WIDTH-1:0] mem_data [0:DEPTH-1];
    wire [DEPTH-1:0] write_sel;
    
    // Address decoder for write operations
    addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) write_decoder (
        .addr(waddr),
        .en(we),
        .sel(write_sel)
    );
    
    // Memory array consisting of individual storage cells
    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin : mem_cell_gen
            storage_cell #(
                .DATA_WIDTH(DATA_WIDTH)
            ) mem_cell (
                .clk(clk),
                .arst_n(arst_n),
                .we(write_sel[i]),
                .wdata(wdata),
                .rdata(mem_data[i])
            );
        end
    endgenerate
    
    // Read controller
    read_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) read_ctrl (
        .raddr(raddr),
        .mem_data(mem_data),
        .rdata(rdata)
    );
    
endmodule

// Address decoder module
module addr_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire                  en,
    output wire [DEPTH-1:0]      sel
);
    // One-hot encoding for address selection
    reg [DEPTH-1:0] decoder_out;
    
    integer j;
    always @(*) begin
        decoder_out = {DEPTH{1'b0}};
        if (en) begin
            decoder_out[addr] = 1'b1;
        end
    end
    
    assign sel = decoder_out;
    
endmodule

// Storage cell module
module storage_cell #(
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  arst_n,
    input  wire                  we,
    input  wire [DATA_WIDTH-1:0] wdata,
    output wire [DATA_WIDTH-1:0] rdata
);
    // Register for data storage
    reg [DATA_WIDTH-1:0] data_reg;
    
    // Asynchronous reset, synchronous write
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            data_reg <= {DATA_WIDTH{1'b0}};
        end
        else if (we) begin
            data_reg <= wdata;
        end
    end
    
    // Continuous read
    assign rdata = data_reg;
    
endmodule

// Read controller module
module read_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire [ADDR_WIDTH-1:0]     raddr,
    input  wire [DATA_WIDTH-1:0]     mem_data [0:DEPTH-1],
    output wire [DATA_WIDTH-1:0]     rdata
);
    // Multiplexer for read operation
    reg [DATA_WIDTH-1:0] read_data;
    
    always @(*) begin
        read_data = mem_data[raddr];
    end
    
    assign rdata = read_data;
    
endmodule