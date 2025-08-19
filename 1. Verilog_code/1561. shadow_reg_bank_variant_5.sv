//SystemVerilog
module shadow_reg_bank #(parameter DW=8, AW=4) (
    input clk,
    input rst_n,
    input we,
    input valid_in,
    input [AW-1:0] addr,
    input [DW-1:0] wdata,
    output [DW-1:0] rdata,
    output reg valid_out
);
    // Memory array
    reg [DW-1:0] shadow_mem [2**AW-1:0];
    
    // Pipeline stage 1 registers
    reg [AW-1:0] addr_stage1;
    reg [DW-1:0] wdata_stage1;
    reg we_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [DW-1:0] rdata_stage2;

    // Stage 1: Register inputs and perform write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {AW{1'b0}};
            wdata_stage1 <= {DW{1'b0}};
            we_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            wdata_stage1 <= wdata;
            we_stage1 <= we;
            valid_stage1 <= valid_in;
            
            // Write operation in stage 1
            if (we_stage1) begin
                shadow_mem[addr_stage1] <= wdata_stage1;
            end
        end
    end
    
    // Stage 2: Read data and register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_stage2 <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            rdata_stage2 <= shadow_mem[addr_stage1];
            valid_out <= valid_stage1;
        end
    end
    
    // Output assignment
    assign rdata = rdata_stage2;
    
endmodule