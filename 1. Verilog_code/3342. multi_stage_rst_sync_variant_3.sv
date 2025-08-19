//SystemVerilog
module multi_stage_rst_sync #(
    parameter STAGES = 3
)(
    input  wire clock,
    input  wire raw_rst_n,
    output wire clean_rst_n
);
    reg [STAGES-1:0] sync_chain;
    
    always @(posedge clock or negedge raw_rst_n) begin
        sync_chain <= (!raw_rst_n) ? {STAGES{1'b0}} : {sync_chain[STAGES-2:0], 1'b1};
    end
    
    assign clean_rst_n = sync_chain[STAGES-1];
endmodule

module parallel_prefix_subtractor_8bit (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    input  wire       borrow_in,
    output wire [7:0] difference,
    output wire       borrow_out
);
    wire [7:0] generate_borrow;
    wire [7:0] propagate_borrow;
    wire [7:0] prefix_borrow;

    // Generate and Propagate signals
    assign generate_borrow   = ~minuend & subtrahend;
    assign propagate_borrow  = ~(minuend ^ subtrahend);

    // Parallel Prefix Borrow Tree
    wire [7:0] stage1_borrow;

    assign stage1_borrow[0] = generate_borrow[0] | (propagate_borrow[0] & borrow_in);
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : stage1
            assign stage1_borrow[i] = generate_borrow[i] | (propagate_borrow[i] & stage1_borrow[i-1]);
        end
    endgenerate

    // Assign prefix_borrow
    assign prefix_borrow = {stage1_borrow[6:0], borrow_in};

    // Difference calculation
    assign difference = minuend ^ subtrahend ^ prefix_borrow;

    // Final borrow out
    assign borrow_out = stage1_borrow[7];
endmodule