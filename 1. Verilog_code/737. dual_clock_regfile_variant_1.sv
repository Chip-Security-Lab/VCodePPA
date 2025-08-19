//SystemVerilog
module dual_clock_regfile #(
    parameter DW = 48,
    parameter AW = 5
)(
    input wr_clk,
    input rd_clk,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] wr_data,
    input [AW-1:0] rd_addr,
    output [DW-1:0] rd_data
);
    // Memory array
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // Read pipeline registers
    reg [AW-1:0] rd_addr_stage1;
    reg rd_valid_stage1;
    reg [DW-1:0] rd_data_stage1;
    reg [DW-1:0] rd_data_stage2;
    reg rd_valid_stage2;
    
    // Write pipeline registers
    reg [AW-1:0] wr_addr_stage1;
    reg [DW-1:0] wr_data_stage1;
    reg wr_en_stage1;
    
    // Fanout buffers for read address
    reg [AW-1:0] rd_addr_buf1, rd_addr_buf2;
    
    // Fanout buffers for memory read data
    reg [DW-1:0] mem_data_buf;
    
    // Write pipeline stage 1: Register inputs
    always @(posedge wr_clk) begin
        wr_addr_stage1 <= wr_addr;
        wr_data_stage1 <= wr_data;
        wr_en_stage1 <= wr_en;
    end
    
    // Write pipeline stage 2: Perform memory write
    always @(posedge wr_clk) begin
        if (wr_en_stage1) mem[wr_addr_stage1] <= wr_data_stage1;
    end
    
    // Read address fanout buffering
    always @(posedge rd_clk) begin
        rd_addr_buf1 <= rd_addr;
        rd_addr_buf2 <= rd_addr;
        rd_addr_stage1 <= rd_addr_buf1;
    end
    
    // Read data fanout buffering
    always @(posedge rd_clk) begin
        mem_data_buf <= mem[rd_addr_buf2];
    end
    
    // Read pipeline stage 1: Register address and fetch data
    always @(posedge rd_clk) begin
        rd_valid_stage1 <= 1'b1;
        rd_data_stage1 <= mem_data_buf;
    end
    
    // Read pipeline stage 2: Register read data
    always @(posedge rd_clk) begin
        rd_data_stage2 <= rd_data_stage1;
        rd_valid_stage2 <= rd_valid_stage1;
    end
    
    // Output assignment
    assign rd_data = rd_data_stage2;
endmodule