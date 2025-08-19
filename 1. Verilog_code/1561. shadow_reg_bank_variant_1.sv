//SystemVerilog
module shadow_reg_bank_pipeline #(parameter DW=8, AW=4) (
    input clk, we,
    input [AW-1:0] addr,
    input [DW-1:0] wdata,
    output [DW-1:0] rdata
);
    reg [DW-1:0] shadow_mem [2**AW-1:0];
    reg [DW-1:0] output_reg_stage1, output_reg_stage2;
    reg valid_stage1, valid_stage2;
    reg [DW-1:0] buffer_stage1;

    // 合并所有posedge clk触发的always块
    always @(posedge clk) begin
        // Stage 1: Write to memory and pass to buffer
        if(we) begin
            shadow_mem[addr] <= wdata;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
        buffer_stage1 <= shadow_mem[addr];
        
        // Stage 2: Pass the buffered output to final register
        output_reg_stage1 <= buffer_stage1;
        output_reg_stage2 <= output_reg_stage1;
        valid_stage2 <= valid_stage1;
    end

    assign rdata = output_reg_stage2;

endmodule