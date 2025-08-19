//SystemVerilog
module tdp_ram_byte_en #(
    parameter DATA_WIDTH = 32,
    parameter BYTE_SIZE = 8,
    parameter ADDR_WIDTH = 10
)(
    input clk,
    // Port X
    input [ADDR_WIDTH-1:0] x_addr,
    input [DATA_WIDTH-1:0] x_din,
    output reg [DATA_WIDTH-1:0] x_dout,
    input [DATA_WIDTH/BYTE_SIZE-1:0] x_we,
    // Port Y
    input [ADDR_WIDTH-1:0] y_addr,
    input [DATA_WIDTH-1:0] y_din,
    output reg [DATA_WIDTH-1:0] y_dout,
    input [DATA_WIDTH/BYTE_SIZE-1:0] y_we
);

localparam BYTE_NUM = DATA_WIDTH/BYTE_SIZE;
reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
integer i, j;

// Pipeline registers for address and data
reg [ADDR_WIDTH-1:0] x_addr_reg, y_addr_reg;
reg [DATA_WIDTH-1:0] x_din_reg, y_din_reg;
reg [DATA_WIDTH/BYTE_SIZE-1:0] x_we_reg, y_we_reg;
reg [DATA_WIDTH-1:0] x_dout_reg, y_dout_reg;

// First pipeline stage - register inputs
always @(posedge clk) begin
    x_addr_reg <= x_addr;
    y_addr_reg <= y_addr;
    x_din_reg <= x_din;
    y_din_reg <= y_din;
    x_we_reg <= x_we;
    y_we_reg <= y_we;
end

// Second pipeline stage - memory access and write operations
always @(posedge clk) begin
    // Read operations
    x_dout_reg <= mem[x_addr_reg];
    y_dout_reg <= mem[y_addr_reg];
    
    // Write operations for Port X using two's complement addition
    for (i=0; i<BYTE_NUM; i=i+1) begin
        if (x_we_reg[i]) begin
            mem[x_addr_reg][i*BYTE_SIZE +: BYTE_SIZE] <= 
                ~x_din_reg[i*BYTE_SIZE +: BYTE_SIZE] + 1'b1;
        end
    end

    // Write operations for Port Y using two's complement addition
    for (j=0; j<BYTE_NUM; j=j+1) begin
        if (y_we_reg[j]) begin
            mem[y_addr_reg][j*BYTE_SIZE +: BYTE_SIZE] <= 
                ~y_din_reg[j*BYTE_SIZE +: BYTE_SIZE] + 1'b1;
        end
    end
end

// Third pipeline stage - output registers
always @(posedge clk) begin
    x_dout <= x_dout_reg;
    y_dout <= y_dout_reg;
end

endmodule