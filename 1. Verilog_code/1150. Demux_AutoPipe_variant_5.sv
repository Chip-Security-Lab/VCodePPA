//SystemVerilog
module Demux_AutoPipe #(
    parameter DW = 8,  // Data width
    parameter AW = 2   // Address width
)(
    input wire clk,
    input wire rst,
    input wire [AW-1:0] addr,
    input wire [DW-1:0] din,
    input wire valid_in,
    output wire valid_out,
    output reg [(1<<AW)-1:0][DW-1:0] dout
);
    // Stage 1 registers
    reg [AW-1:0] addr_stage1;
    reg [DW-1:0] din_stage1;
    reg valid_stage1;
    reg [(1<<AW)-1:0] one_hot_addr_stage1;
    
    // Stage 2 registers
    reg [(1<<AW)-1:0][DW-1:0] pipe_reg_stage2;
    reg valid_stage2;
    
    // Stage 3 registers
    reg [(1<<AW)-1:0][DW-1:0] dout_stage3;
    reg valid_stage3;
    
    // Stage 1: Input registration and one-hot encoding
    always @(posedge clk) begin
        if (rst) begin
            addr_stage1 <= '0;
            din_stage1 <= '0;
            one_hot_addr_stage1 <= '0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            din_stage1 <= din;
            one_hot_addr_stage1 <= (1'b1 << addr);
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Data processing and channel selection
    always @(posedge clk) begin
        if (rst) begin
            pipe_reg_stage2 <= '0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            // Apply selected data to the correct output channel
            for (int i = 0; i < (1<<AW); i++) begin
                if (i == addr_stage1) begin
                    pipe_reg_stage2[i] <= din_stage1;
                end else begin
                    // Maintain the existing value
                    pipe_reg_stage2[i] <= pipe_reg_stage2[i];
                end
            end
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk) begin
        if (rst) begin
            dout_stage3 <= '0;
            valid_stage3 <= 1'b0;
        end else begin
            dout_stage3 <= pipe_reg_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Connect output signals
    assign valid_out = valid_stage3;
    
    // Final output assignment
    always @(*) begin
        dout = dout_stage3;
    end
endmodule