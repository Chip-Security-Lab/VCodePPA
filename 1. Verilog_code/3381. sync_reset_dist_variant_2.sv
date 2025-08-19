//SystemVerilog
module sync_reset_dist(
    input wire clk,
    input wire rst_in,
    output reg [7:0] rst_out
);
    // Intermediate signals - combinational logic is moved before registers
    wire rst_stage1;
    wire [3:0] rst_stage2;
    
    // Direct connection to input (moved combinational logic before registers)
    assign rst_stage1 = rst_in;
    
    // Direct fanout connections (no registers yet)
    assign rst_stage2[0] = rst_stage1;
    assign rst_stage2[1] = rst_stage1;
    assign rst_stage2[2] = rst_stage1;
    assign rst_stage2[3] = rst_stage1;
    
    // All registers moved to final output stage (forward retiming)
    // This reduces input-to-register delay by moving registers forward
    always @(posedge clk) begin
        rst_out[1:0] <= {2{rst_stage2[0]}};
        rst_out[3:2] <= {2{rst_stage2[1]}};
        rst_out[5:4] <= {2{rst_stage2[2]}};
        rst_out[7:6] <= {2{rst_stage2[3]}};
    end
endmodule