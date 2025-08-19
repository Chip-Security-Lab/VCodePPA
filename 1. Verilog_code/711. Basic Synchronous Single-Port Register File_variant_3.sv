//SystemVerilog
// Memory array submodule
module regfile_memory #(
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
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Read operation (combinational)
    assign rdata = mem[addr];
    
    // Write operation (sequential)
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end 
        else if (we) begin
            mem[addr] <= wdata;
        end
    end
endmodule

// Write control submodule
module regfile_write_ctrl #(
    parameter ADDR_WIDTH = 5
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  addr,
    output wire                   write_en,
    output wire [ADDR_WIDTH-1:0]  write_addr
);
    reg write_en_reg;
    reg [ADDR_WIDTH-1:0] write_addr_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_en_reg <= 1'b0;
            write_addr_reg <= {ADDR_WIDTH{1'b0}};
        end else begin
            write_en_reg <= we;
            write_addr_reg <= addr;
        end
    end
    
    assign write_en = write_en_reg;
    assign write_addr = write_addr_reg;
endmodule

// Top-level register file module
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
    wire write_en;
    wire [ADDR_WIDTH-1:0] write_addr;
    
    // Instantiate write control
    regfile_write_ctrl #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) write_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .we(we),
        .addr(addr),
        .write_en(write_en),
        .write_addr(write_addr)
    );
    
    // Instantiate memory array
    regfile_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) memory (
        .clk(clk),
        .rst_n(rst_n),
        .we(write_en),
        .addr(write_addr),
        .wdata(wdata),
        .rdata(rdata)
    );
endmodule