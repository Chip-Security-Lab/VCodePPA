//SystemVerilog
module shadow_reg_bank #(parameter DW=8, AW=4) (
    input clk, we,
    input [AW-1:0] addr,
    input [DW-1:0] wdata,
    output [DW-1:0] rdata
);
    reg [DW-1:0] shadow_mem [2**AW-1:0];
    reg [DW-1:0] output_reg_stage1, output_reg_stage2; // Pipeline registers for optimization
    reg [DW-1:0] temp_reg_stage1, temp_reg_stage2; // Additional pipeline registers

    always @(posedge clk) begin
        if (we) 
            shadow_mem[addr] <= wdata;
    end

    always @(posedge clk) begin
        temp_reg_stage1 <= shadow_mem[addr]; // First stage of pipelining
    end

    always @(posedge clk) begin
        output_reg_stage1 <= temp_reg_stage1; // Second stage of pipelining
    end

    always @(posedge clk) begin
        output_reg_stage2 <= output_reg_stage1; // Third stage of pipelining
    end

    assign rdata = output_reg_stage2; // Output from the final stage
endmodule