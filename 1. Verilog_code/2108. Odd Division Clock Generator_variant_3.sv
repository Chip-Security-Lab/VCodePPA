//SystemVerilog
// Top-level module: Odd Division Clock Generator (Hierarchical Structure)
module odd_div_clk_gen #(
    parameter DIV = 3  // Must be odd number
)(
    input  wire clk_in,
    input  wire rst,
    output wire clk_out
);

    // Internal signal declarations
    wire [$clog2(DIV)-1:0] count_current;
    wire [$clog2(DIV)-1:0] count_next;
    wire                   clk_toggle;
    wire                   clk_out_next;
    wire                   clk_out_reg;

    // Counter logic submodule instantiation
    odd_div_counter #(
        .DIV(DIV)
    ) u_counter (
        .clk_in    (clk_in),
        .rst       (rst),
        .count_out (count_current),
        .count_next(count_next)
    );

    // Toggle logic submodule instantiation
    odd_div_toggle #(
        .DIV(DIV)
    ) u_toggle (
        .count_current(count_current),
        .clk_out_reg  (clk_out_reg),
        .clk_toggle   (clk_toggle)
    );

    // Output register logic submodule instantiation
    odd_div_output_reg u_output_reg (
        .clk_in      (clk_in),
        .rst         (rst),
        .clk_toggle  (clk_toggle),
        .clk_out_reg (clk_out_reg),
        .clk_out     (clk_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: odd_div_counter
// Function: Handles modulo-DIV counter logic for clock division
// -----------------------------------------------------------------------------
module odd_div_counter #(
    parameter DIV = 3
)(
    input  wire                     clk_in,
    input  wire                     rst,
    output reg  [$clog2(DIV)-1:0]   count_out,
    output reg  [$clog2(DIV)-1:0]   count_next
);
    always @* begin
        if (count_out == DIV-1)
            count_next = 0;
        else
            count_next = count_out + 1;
    end

    always @(posedge clk_in or posedge rst) begin
        if (rst)
            count_out <= 0;
        else
            count_out <= count_next;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: odd_div_toggle
// Function: Determines when to toggle clk_out based on counter value
// -----------------------------------------------------------------------------
module odd_div_toggle #(
    parameter DIV = 3
)(
    input  wire [$clog2(DIV)-1:0] count_current,
    input  wire                   clk_out_reg,
    output reg                    clk_toggle
);
    localparam HALF = (DIV-1)/2;

    always @* begin
        if (count_current == 0 || count_current == (HALF+1))
            clk_toggle = 1'b1;
        else
            clk_toggle = 1'b0;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: odd_div_output_reg
// Function: Implements output clock register with toggle control and reset
// -----------------------------------------------------------------------------
module odd_div_output_reg (
    input  wire clk_in,
    input  wire rst,
    input  wire clk_toggle,
    output reg  clk_out_reg,
    output wire clk_out
);
    always @(posedge clk_in or posedge rst) begin
        if (rst)
            clk_out_reg <= 1'b0;
        else if (clk_toggle)
            clk_out_reg <= ~clk_out_reg;
    end

    assign clk_out = clk_out_reg;
endmodule