//SystemVerilog
module asymmetric_regfile #(
    parameter WR_DW = 64,
    parameter RD_DW = 32
)(
    input clk,
    input wr_en,
    input [2:0] wr_addr,
    input [WR_DW-1:0] din,
    input [3:0] rd_addr,
    output reg [RD_DW-1:0] dout
);
    reg [WR_DW-1:0] mem [0:7];
    wire sel_high = rd_addr[3];
    wire [2:0] actual_rd_addr = rd_addr[2:0];
    
    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= din;
        end
    end
    
    always @(posedge clk) begin
        if (sel_high && (actual_rd_addr >= 0) && (actual_rd_addr <= 7)) begin
            dout <= mem[actual_rd_addr][WR_DW-1:RD_DW];
        end else if (!sel_high && (actual_rd_addr >= 0) && (actual_rd_addr <= 7)) begin
            dout <= mem[actual_rd_addr][RD_DW-1:0];
        end
    end
endmodule