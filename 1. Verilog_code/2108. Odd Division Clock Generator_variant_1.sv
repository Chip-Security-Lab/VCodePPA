//SystemVerilog
// Top module: uses reusable odd divider module
module odd_div_clk_gen #(
    parameter DIV = 3  // Must be odd number
)(
    input clk_in,
    input rst,
    output clk_out
);

    odd_divider #(
        .DIV(DIV)
    ) u_odd_divider (
        .clk(clk_in),
        .rst(rst),
        .div_clk(clk_out)
    );

endmodule

// Reusable parameterized odd divider module
module odd_divider #(
    parameter DIV = 3  // Must be odd number
)(
    input clk,
    input rst,
    output reg div_clk
);
    localparam HALF = (DIV-1)/2;
    reg [$clog2(DIV)-1:0] div_count;

    // Simplified Boolean logic for toggle condition:
    // Original: (div_count == 0 || div_count == HALF+1)
    // Simplified: (div_count == 0) | (div_count == (HALF+1))
    wire toggle_clk;
    assign toggle_clk = (div_count == 0) | (div_count == (HALF + 1));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div_count <= 0;
            div_clk <= 0;
        end else begin
            if (div_count == (DIV - 1)) begin
                div_count <= 0;
            end else begin
                div_count <= div_count + 1;
            end

            if (toggle_clk)
                div_clk <= ~div_clk;
        end
    end
endmodule