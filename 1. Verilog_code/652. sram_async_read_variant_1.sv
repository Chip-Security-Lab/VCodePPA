//SystemVerilog
module sram_async_read #(
    parameter DW = 16,
    parameter AW = 5
)(
    input wr_clk,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] wr_data,
    input rd_en,
    input [AW-1:0] rd_addr,
    output reg [DW-1:0] rd_data
);

reg [DW-1:0] storage [0:(1<<AW)-1];
reg [AW-1:0] rd_addr_stage1;
reg rd_en_stage1;
reg [DW-1:0] rd_data_stage1;

// Merged always block for all synchronous operations
always @(posedge wr_clk) begin
    // Stage 1: Address and enable registration
    rd_addr_stage1 <= rd_addr;
    rd_en_stage1 <= rd_en;
    
    // Stage 2: Memory write and read
    if (wr_en) 
        storage[wr_addr] <= wr_data;
    
    rd_data_stage1 <= rd_en_stage1 ? storage[rd_addr_stage1] : {DW{1'bz}};
    
    // Stage 3: Output registration
    rd_data <= rd_data_stage1;
end

endmodule