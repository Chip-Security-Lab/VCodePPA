//SystemVerilog
// Top-level module: Hierarchical Tree Multiplexer

module TreeMux #(parameter DW=8, N=8) (
    input  wire [DW-1:0] din [N-1:0],
    input  wire [$clog2(N)-1:0] sel,
    output wire [DW-1:0] dout
);

    // Internal signal for mux output
    wire [DW-1:0] mux_output;

    // Instantiate the multiplexer logic submodule
    TreeMux_MuxLogic #(.DW(DW), .N(N)) u_mux_logic (
        .data_in (din),
        .select  (sel),
        .data_out(mux_output)
    );

    // Output assignment
    assign dout = mux_output;

endmodule

// -----------------------------------------------------------
// Submodule: TreeMux_MuxLogic
// Function: Implements the one-hot multiplexer logic
// Parameters:
//   DW - Data width of each input
//   N  - Number of input channels
// -----------------------------------------------------------
module TreeMux_MuxLogic #(parameter DW=8, N=8) (
    input  wire [DW-1:0] data_in [N-1:0],
    input  wire [$clog2(N)-1:0] select,
    output reg  [DW-1:0] data_out
);

    integer i;

    always @* begin
        data_out = {DW{1'b0}};
        for (i = 0; i < N; i = i + 1) begin
            if (select == i[$clog2(N)-1:0])
                data_out = data_in[i];
        end
    end

endmodule