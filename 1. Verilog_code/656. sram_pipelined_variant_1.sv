//SystemVerilog
module sram_pipelined #(
    parameter DW = 64,
    parameter AW = 8
)(
    input clk,
    input rst_n,
    input ce,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [AW-1:0] addr_stage1, addr_stage2;
reg [DW-1:0] data_stage1, data_stage2, data_stage3;
reg we_stage1, we_stage2;
reg ce_stage1, ce_stage2;
reg valid_stage1, valid_stage2, valid_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage1 <= 0;
        addr_stage2 <= 0;
        data_stage1 <= 0;
        data_stage2 <= 0;
        data_stage3 <= 0;
        we_stage1 <= 0;
        we_stage2 <= 0;
        ce_stage1 <= 0;
        ce_stage2 <= 0;
        valid_stage1 <= 0;
        valid_stage2 <= 0;
        valid_stage3 <= 0;
        dout <= 0;
    end else begin
        // Stage 1: Address and control signal pipeline
        addr_stage1 <= addr;
        we_stage1 <= we;
        ce_stage1 <= ce;
        valid_stage1 <= ce;
        
        // Stage 2: Memory access pipeline
        addr_stage2 <= addr_stage1;
        we_stage2 <= we_stage1;
        ce_stage2 <= ce_stage1;
        valid_stage2 <= valid_stage1;
        
        if (ce_stage1) begin
            if (we_stage1) begin
                mem[addr_stage1] <= din;
                data_stage1 <= din;
            end else begin
                data_stage1 <= mem[addr_stage1];
            end
        end
        
        // Stage 3: Data pipeline
        data_stage2 <= data_stage1;
        valid_stage3 <= valid_stage2;
        
        // Stage 4: Output pipeline
        data_stage3 <= data_stage2;
        if (valid_stage3) begin
            dout <= data_stage3;
        end
    end
end

endmodule