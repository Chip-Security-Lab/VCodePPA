//SystemVerilog
module tdp_ram_byte_en_pipeline #(
    parameter DATA_WIDTH = 32,
    parameter BYTE_SIZE = 8,
    parameter ADDR_WIDTH = 10
)(
    input clk,
    input rst_n,
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

localparam BYTE_NUM = DATA_WIDTH / BYTE_SIZE;
reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH) - 1];

// Pipeline stage 1: Address and data capture
reg [ADDR_WIDTH-1:0] x_addr_stage1, y_addr_stage1;
reg [DATA_WIDTH-1:0] x_din_stage1, y_din_stage1;
reg [DATA_WIDTH/BYTE_SIZE-1:0] x_we_stage1, y_we_stage1;

// Pipeline stage 2: Memory read
reg [DATA_WIDTH-1:0] x_dout_stage2, y_dout_stage2;

// Pipeline stage 3: Memory write and output
reg [DATA_WIDTH-1:0] x_dout_stage3, y_dout_stage3;

// Stage 1: Capture inputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_addr_stage1 <= 0;
        y_addr_stage1 <= 0;
        x_din_stage1 <= 0;
        y_din_stage1 <= 0;
        x_we_stage1 <= 0;
        y_we_stage1 <= 0;
    end else begin
        x_addr_stage1 <= x_addr;
        y_addr_stage1 <= y_addr;
        x_din_stage1 <= x_din;
        y_din_stage1 <= y_din;
        x_we_stage1 <= x_we;
        y_we_stage1 <= y_we;
    end
end

// Stage 2: Memory read
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_dout_stage2 <= 0;
        y_dout_stage2 <= 0;
    end else begin
        x_dout_stage2 <= mem[x_addr_stage1];
        y_dout_stage2 <= mem[y_addr_stage1];
    end
end

// Stage 3: Memory write and output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_dout_stage3 <= 0;
        y_dout_stage3 <= 0;
        x_dout <= 0;
        y_dout <= 0;
    end else begin
        x_dout_stage3 <= x_dout_stage2;
        y_dout_stage3 <= y_dout_stage2;
        x_dout <= x_dout_stage3;
        y_dout <= y_dout_stage3;

        // Port X byte-wise write
        for (integer i = 0; i < BYTE_NUM; i = i + 1) begin
            if (x_we_stage1[i]) begin
                mem[x_addr_stage1][i*BYTE_SIZE +: BYTE_SIZE] <= x_din_stage1[i*BYTE_SIZE +: BYTE_SIZE];
            end
        end

        // Port Y byte-wise write
        for (integer j = 0; j < BYTE_NUM; j = j + 1) begin
            if (y_we_stage1[j]) begin
                mem[y_addr_stage1][j*BYTE_SIZE +: BYTE_SIZE] <= y_din_stage1[j*BYTE_SIZE +: BYTE_SIZE];
            end
        end
    end
end

endmodule