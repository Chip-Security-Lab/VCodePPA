//SystemVerilog

// -----------------------------------------------------------------------------
// Submodule: priority_detector
// Function: Detects if any request is active and outputs a valid signal
// -----------------------------------------------------------------------------
module priority_detector #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] requests,
    output wire             valid
);
    assign valid = |requests;
endmodule

// -----------------------------------------------------------------------------
// Submodule: priority_index_finder
// Function: Finds the highest-priority active request index
// -----------------------------------------------------------------------------
module priority_index_finder #(
    parameter WIDTH = 8,
    parameter OUT_WIDTH = 3 // Default for WIDTH=8
)(
    input  wire [WIDTH-1:0] requests,
    output reg  [OUT_WIDTH-1:0] grant_idx
);
    integer idx;
    always @(*) begin
        grant_idx = {OUT_WIDTH{1'b0}};
        for (idx = WIDTH-1; idx >= 0; idx = idx - 1) begin
            if (requests[idx]) begin
                grant_idx = idx[OUT_WIDTH-1:0];
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Top Module: priority_encoder
// Function: Top-level priority encoder, instantiates detector and index finder
// -----------------------------------------------------------------------------
module priority_encoder #(
    parameter WIDTH = 8,
    parameter OUT_WIDTH = 3 // $clog2(WIDTH) is not synthesizable; use parameter
)(
    input  wire [WIDTH-1:0] requests,
    output wire [OUT_WIDTH-1:0] grant_idx,
    output wire                 valid
);

    // Internal signal for grant index
    wire [OUT_WIDTH-1:0] grant_idx_int;

    // Instantiate validity detector
    priority_detector #(
        .WIDTH(WIDTH)
    ) u_priority_detector (
        .requests(requests),
        .valid(valid)
    );

    // Instantiate index finder
    priority_index_finder #(
        .WIDTH(WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_priority_index_finder (
        .requests(requests),
        .grant_idx(grant_idx_int)
    );

    // Assign outputs
    assign grant_idx = grant_idx_int;

endmodule