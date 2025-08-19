//SystemVerilog
module regfile_2r1w_sync #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 32
)(
    input clk,
    input rst_n,
    input wr_en,
    input [ADDR_WIDTH-1:0] rd_addr0,
    input [ADDR_WIDTH-1:0] rd_addr1,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [DATA_WIDTH-1:0] wr_data,
    output reg [DATA_WIDTH-1:0] rd_data0,
    output reg [DATA_WIDTH-1:0] rd_data1
);

// LUT-based memory implementation
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
reg [DATA_WIDTH-1:0] mem_buf0 [0:DEPTH-1];
reg [DATA_WIDTH-1:0] mem_buf1 [0:DEPTH-1];

// Pre-computed LUT for address decoding
reg [DEPTH-1:0] wr_decode;
reg [DEPTH-1:0] rd_decode0;
reg [DEPTH-1:0] rd_decode1;

// Address decoder logic
always @(*) begin
    wr_decode = 0;
    wr_decode[wr_addr] = wr_en;
    
    rd_decode0 = 0;
    rd_decode0[rd_addr0] = 1'b1;
    
    rd_decode1 = 0;
    rd_decode1[rd_addr1] = 1'b1;
end

// Memory write with LUT-based addressing
always @(posedge clk) begin
    if (!rst_n) begin
        for (int i=0; i<DEPTH; i=i+1) begin
            mem[i] <= 0;
            mem_buf0[i] <= 0;
            mem_buf1[i] <= 0;
        end
    end else begin
        // Parallel write using LUT
        for (int i=0; i<DEPTH; i=i+1) begin
            if (wr_decode[i]) begin
                mem[i] <= wr_data;
            end
        end
    end
end

// Pipeline registers for read data
reg [DATA_WIDTH-1:0] rd_data0_reg;
reg [DATA_WIDTH-1:0] rd_data1_reg;

// Read with LUT-based addressing
always @(posedge clk) begin
    // Parallel read using LUT
    for (int i=0; i<DEPTH; i=i+1) begin
        if (rd_decode0[i]) begin
            rd_data0_reg <= mem_buf0[i];
        end
        if (rd_decode1[i]) begin
            rd_data1_reg <= mem_buf1[i];
        end
    end
end

// Assign to output registers
always @(posedge clk) begin
    rd_data0 <= rd_data0_reg;
    rd_data1 <= rd_data1_reg;
end

endmodule