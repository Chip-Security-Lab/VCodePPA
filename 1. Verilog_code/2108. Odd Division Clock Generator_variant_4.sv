//SystemVerilog
//===============================================================
// Top-level Odd Divider Clock Generator
//===============================================================
module odd_div_clk_gen #(
    parameter DIV = 3  // Must be odd number
)(
    input  wire clk_in,
    input  wire rst,
    output wire clk_out
);

    // Internal signals
    wire [$clog2(DIV)-1:0] div_count;
    wire                   div_last_count;
    wire                   clk_toggled;

    // Counter instance
    odd_div_counter #(
        .DIV(DIV)
    ) u_odd_div_counter (
        .clk        (clk_in),
        .rst        (rst),
        .count      (div_count),
        .last_count (div_last_count)
    );

    // Toggle logic instance
    odd_div_toggle #(
        .DIV(DIV)
    ) u_odd_div_toggle (
        .clk            (clk_in),
        .rst            (rst),
        .count          (div_count),
        .clk_toggled    (clk_toggled)
    );

    // Output assignment
    assign clk_out = clk_toggled;

endmodule

//===============================================================
// Counter Submodule
// Function: Parameterized up-counter for odd divider
//===============================================================
module odd_div_counter #(
    parameter DIV = 3
)(
    input  wire clk,
    input  wire rst,
    output reg  [$clog2(DIV)-1:0] count,
    output wire last_count
);
    // Assert when count reaches DIV-1
    assign last_count = (count == (DIV-1));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= {($clog2(DIV)){1'b0}};
        end else begin
            case (count)
                (DIV-1): count <= {($clog2(DIV)){1'b0}};
                default: count <= count + 1'b1;
            endcase
        end
    end
endmodule

//===============================================================
// Toggle Logic Submodule
// Function: Generates output clock toggle based on count value
//===============================================================
module odd_div_toggle #(
    parameter DIV = 3
)(
    input  wire clk,
    input  wire rst,
    input  wire [$clog2(DIV)-1:0] count,
    output reg  clk_toggled
);
    localparam HALF = (DIV-1)/2;
    localparam [$clog2(DIV)-1:0] HALF_PLUS_ONE = HALF + 1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_toggled <= 1'b0;
        end else begin
            case (count)
                {($clog2(DIV)){1'b0}}: clk_toggled <= ~clk_toggled;
                HALF_PLUS_ONE:          clk_toggled <= ~clk_toggled;
                default:                clk_toggled <= clk_toggled;
            endcase
        end
    end
endmodule