//SystemVerilog
//IEEE 1364-2005 Verilog
///////////////////////////////////////////////////////////////////////////////
// Design Name: Hierarchical One-Hot Reset Distribution System
// Module Name: one_hot_reset_dist
// Description: Top level module for one-hot reset distribution
///////////////////////////////////////////////////////////////////////////////
module one_hot_reset_dist #(
    parameter RESET_OUTPUTS = 4,
    parameter SELECT_WIDTH = 2
)(
    input wire clk,
    input wire [SELECT_WIDTH-1:0] reset_select,
    input wire reset_in,
    output wire [RESET_OUTPUTS-1:0] reset_out
);

    // Decoded one-hot reset signal
    wire [RESET_OUTPUTS-1:0] decoded_reset;

    // Instantiate decoder module
    reset_decoder #(
        .OUTPUTS(RESET_OUTPUTS),
        .SELECT_WIDTH(SELECT_WIDTH)
    ) u_reset_decoder (
        .reset_select(reset_select),
        .reset_in(reset_in),
        .decoded_reset(decoded_reset)
    );

    // Instantiate synchronizer module
    reset_synchronizer #(
        .RESET_WIDTH(RESET_OUTPUTS)
    ) u_reset_synchronizer (
        .clk(clk),
        .reset_in(decoded_reset),
        .reset_out(reset_out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module Name: reset_decoder
// Description: Decodes the reset select into a one-hot encoded signal
///////////////////////////////////////////////////////////////////////////////
module reset_decoder #(
    parameter OUTPUTS = 4,
    parameter SELECT_WIDTH = 2
)(
    input wire [SELECT_WIDTH-1:0] reset_select,
    input wire reset_in,
    output reg [OUTPUTS-1:0] decoded_reset
);
    
    always @(*) begin
        decoded_reset = {OUTPUTS{1'b0}}; // Default all to 0
        
        if (reset_in) begin
            // Optimized one-hot decoding using direct indexing
            if (reset_select < OUTPUTS) begin
                decoded_reset[reset_select] = 1'b1;
            end
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module Name: reset_synchronizer
// Description: Synchronizes the reset signals to the clock domain
///////////////////////////////////////////////////////////////////////////////
module reset_synchronizer #(
    parameter RESET_WIDTH = 4,
    parameter SYNC_STAGES = 2  // Added parameter for multi-stage synchronization
)(
    input wire clk,
    input wire [RESET_WIDTH-1:0] reset_in,
    output reg [RESET_WIDTH-1:0] reset_out
);
    // Multi-stage synchronization to prevent metastability
    reg [RESET_WIDTH-1:0] sync_stage [SYNC_STAGES-1:0];
    
    integer i;
    
    always @(posedge clk) begin
        sync_stage[0] <= reset_in;
        
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin
            sync_stage[i] <= sync_stage[i-1];
        end
        
        reset_out <= sync_stage[SYNC_STAGES-1];
    end

endmodule