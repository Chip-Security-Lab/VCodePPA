//SystemVerilog
// Top-level reset synchronizer module with hierarchical structure
module reset_sync #(parameter STAGES = 3) (
    input  wire clk,
    input  wire async_reset_n,
    output wire sync_reset_n
);

    wire [STAGES-1:0] sync_reg_out;

    // Instance: Asynchronous Reset Stage
    reset_sync_async_stage #(.STAGES(STAGES)) u_async_stage (
        .clk             (clk),
        .async_reset_n   (async_reset_n),
        .reset_stage_out (sync_reg_out)
    );

    // Instance: Output Selection Stage
    reset_sync_output_stage #(.STAGES(STAGES)) u_output_stage (
        .reset_stage_in  (sync_reg_out),
        .sync_reset_n    (sync_reset_n)
    );

endmodule

// -------------------------------------------------------------------
// Submodule: Asynchronous Reset Stage
// Function: Synchronize the asynchronous reset to the clock domain
// Implements a chain of flip-flops for metastability filtering
// -------------------------------------------------------------------
module reset_sync_async_stage #(parameter STAGES = 3) (
    input  wire              clk,
    input  wire              async_reset_n,
    output reg  [STAGES-1:0] reset_stage_out
);
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n)
            reset_stage_out <= {STAGES{1'b0}};
        else
            reset_stage_out <= {reset_stage_out[STAGES-2:0], 1'b1};
    end
endmodule

// -------------------------------------------------------------------
// Submodule: Output Selection Stage
// Function: Select the synchronized reset output from the last stage
// -------------------------------------------------------------------
module reset_sync_output_stage #(parameter STAGES = 3) (
    input  wire [STAGES-1:0] reset_stage_in,
    output wire              sync_reset_n
);
    assign sync_reset_n = reset_stage_in[STAGES-1];
endmodule

// -------------------------------------------------------------------
// 8-bit Borrow Lookahead Subtractor
// Implements: A - B = Difference, Borrow-out
// -------------------------------------------------------------------
module borrow_lookahead_subtractor_8bit (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    input  wire       borrow_in,
    output wire [7:0] difference,
    output wire       borrow_out
);
    wire [7:0] generate_borrow;
    wire [7:0] propagate_borrow;
    wire [8:0] borrow_chain;

    assign borrow_chain[0] = borrow_in;

    // Generate and Propagate signals for each bit
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_borrow
            assign generate_borrow[i]  = (~minuend[i]) & subtrahend[i];
            assign propagate_borrow[i] = (~minuend[i]) | subtrahend[i];
            assign borrow_chain[i+1]   = generate_borrow[i] | (propagate_borrow[i] & borrow_chain[i]);
            assign difference[i]       = minuend[i] ^ subtrahend[i] ^ borrow_chain[i];
        end
    endgenerate

    assign borrow_out = borrow_chain[8];

endmodule