//SystemVerilog
//IEEE 1364-2005
module dual_clk_reset_dist(
    input wire clk_a, clk_b,
    input wire master_rst,
    output wire rst_domain_a, rst_domain_b
);
    // Internal registers for synchronization - separate into synchronizer modules
    wire rst_sync_a;
    wire rst_sync_b;
    
    // Instantiate optimized reset synchronizers for each clock domain
    reset_synchronizer #(
        .STAGES(2)
    ) sync_rst_a (
        .clk(clk_a),
        .async_rst(master_rst),
        .sync_rst(rst_sync_a)
    );
    
    reset_synchronizer #(
        .STAGES(2)
    ) sync_rst_b (
        .clk(clk_b),
        .async_rst(master_rst),
        .sync_rst(rst_sync_b)
    );
    
    // Output assignments
    assign rst_domain_a = rst_sync_a;
    assign rst_domain_b = rst_sync_b;
    
endmodule

//SystemVerilog
//IEEE 1364-2005
module reset_synchronizer #(
    parameter STAGES = 2  // Configurable number of synchronizer stages
)(
    input  wire clk,
    input  wire async_rst,
    output wire sync_rst
);
    // Synchronizer flip-flop chain
    (* ASYNC_REG = "TRUE" *)  // Synthesis attribute to ensure proper placement
    reg [STAGES-1:0] sync_reg;
    
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            sync_reg <= {STAGES{1'b1}};  // Initialize all stages to 1 on reset
        end else begin
            sync_reg <= {sync_reg[STAGES-2:0], 1'b0};  // Shift in zeros
        end
    end
    
    // Output is the last stage of the synchronizer
    assign sync_rst = sync_reg[STAGES-1];
    
endmodule