//SystemVerilog
// Upper history submodule
module ITRC_UpperHistory #(
    parameter WIDTH = 4,
    parameter DEPTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_in,
    output reg [WIDTH*(DEPTH/2)-1:0] history_upper
);
    always @(posedge clk) begin
        if (!rst_n)
            history_upper <= 0;
        else
            history_upper <= {history_upper[WIDTH*(DEPTH/2-1)-1:0], int_in};
    end
endmodule

// Lower history submodule
module ITRC_LowerHistory #(
    parameter WIDTH = 4,
    parameter DEPTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] upper_last,
    output reg [WIDTH*(DEPTH/2)-1:0] history_lower
);
    always @(posedge clk) begin
        if (!rst_n)
            history_lower <= 0;
        else
            history_lower <= {history_lower[WIDTH*(DEPTH/2-1)-1:0], upper_last};
    end
endmodule

// History combiner submodule
module ITRC_HistoryCombiner #(
    parameter WIDTH = 4,
    parameter DEPTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH*(DEPTH/2)-1:0] history_upper,
    input [WIDTH*(DEPTH/2)-1:0] history_lower,
    output reg [WIDTH*DEPTH-1:0] history
);
    always @(posedge clk) begin
        if (!rst_n)
            history <= 0;
        else
            history <= {history_upper, history_lower};
    end
endmodule

// Top module
module ITRC_ShiftTracker #(
    parameter WIDTH = 4,
    parameter DEPTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_in,
    output [WIDTH*DEPTH-1:0] history
);
    wire [WIDTH*(DEPTH/2)-1:0] history_upper;
    wire [WIDTH*(DEPTH/2)-1:0] history_lower;
    wire [WIDTH-1:0] upper_last = history_upper[WIDTH*(DEPTH/2)-1:WIDTH*(DEPTH/2-1)];

    ITRC_UpperHistory #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) upper_inst (
        .clk(clk),
        .rst_n(rst_n),
        .int_in(int_in),
        .history_upper(history_upper)
    );

    ITRC_LowerHistory #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) lower_inst (
        .clk(clk),
        .rst_n(rst_n),
        .upper_last(upper_last),
        .history_lower(history_lower)
    );

    ITRC_HistoryCombiner #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) combiner_inst (
        .clk(clk),
        .rst_n(rst_n),
        .history_upper(history_upper),
        .history_lower(history_lower),
        .history(history)
    );
endmodule