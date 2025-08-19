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
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // 读取路径流水线化
    reg [AW-1:0] rd_addr_pipe;
    reg [DW-1:0] mem_data_pipe;
    reg [DW-1:0] sync_reg;
    
    always @(posedge wr_clk or posedge rd_clk) begin
        if (wr_en) 
            mem[wr_addr] <= wr_data;
        
        if (rd_clk) begin
            rd_addr_pipe <= rd_addr;
            mem_data_pipe <= mem[rd_addr_pipe];
            sync_reg <= mem_data_pipe;
        end
    end
    
    assign rd_data = sync_reg;
endmodule