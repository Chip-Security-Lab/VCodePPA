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

// Port X byte-wise write
always @(posedge clk) begin
    x_dout <= mem[x_addr]; // Read-first behavior
    for (i=0; i<BYTE_NUM; i=i+1) begin
        if (x_we[i]) begin
            mem[x_addr][i*BYTE_SIZE +: BYTE_SIZE] <= x_din[i*BYTE_SIZE +: BYTE_SIZE];
        end
    end
end

// Port Y byte-wise write
always @(posedge clk) begin
    y_dout <= mem[y_addr];
    for (j=0; j<BYTE_NUM; j=j+1) begin
        if (y_we[j]) begin
            mem[y_addr][j*BYTE_SIZE +: BYTE_SIZE] <= y_din[j*BYTE_SIZE +: BYTE_SIZE];
        end
    end
end
endmodule