//SystemVerilog
module dual_port_async_rst #(parameter ADDR_WIDTH=4, DATA_WIDTH=8)(
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] addr_wr, addr_rd,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

// Registered inputs to improve timing at input boundaries
reg wr_en_reg;
reg [ADDR_WIDTH-1:0] addr_wr_reg, addr_rd_reg;
reg [DATA_WIDTH-1:0] din_reg;
reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
reg [DATA_WIDTH-1:0] read_data;

// Register inputs - flattened if-else structure
always @(posedge clk or posedge rst) begin
    if (rst) begin
        wr_en_reg <= 1'b0;
        addr_wr_reg <= {ADDR_WIDTH{1'b0}};
        addr_rd_reg <= {ADDR_WIDTH{1'b0}};
        din_reg <= {DATA_WIDTH{1'b0}};
    end else if (!rst) begin
        wr_en_reg <= wr_en;
        addr_wr_reg <= addr_wr;
        addr_rd_reg <= addr_rd;
        din_reg <= din;
    end
end

// Memory write operation with registered inputs - flattened structure
always @(posedge clk) begin
    if (wr_en_reg)
        mem[addr_wr_reg] <= din_reg;
end

// Memory read operation - flattened if-else structure  
always @(posedge clk or posedge rst) begin
    if (rst)
        read_data <= {DATA_WIDTH{1'b0}};
    else if (!rst)
        read_data <= mem[addr_rd_reg];
end

// Output register - flattened if-else structure
always @(posedge clk or posedge rst) begin
    if (rst)
        dout <= {DATA_WIDTH{1'b0}};
    else if (!rst)
        dout <= read_data;
end

endmodule