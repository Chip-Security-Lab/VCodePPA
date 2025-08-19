//SystemVerilog
// Pattern selector module
module pattern_selector #(parameter W = 8, BANKS = 4) (
    input clk, rst_n,
    input [W-1:0] patterns [BANKS-1:0],
    input [$clog2(BANKS)-1:0] bank_sel,
    output reg [W-1:0] selected_pattern
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            selected_pattern <= {W{1'b0}};
        else
            selected_pattern <= patterns[bank_sel];
    end

endmodule

// Pattern comparator module
module pattern_comparator #(parameter W = 8) (
    input clk, rst_n,
    input [W-1:0] data,
    input [W-1:0] selected_pattern,
    output reg comparison_result
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            comparison_result <= 1'b0;
        else
            comparison_result <= (data == selected_pattern);
    end

endmodule

// Output register module
module output_register (
    input clk, rst_n,
    input comparison_result,
    output reg match
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match <= 1'b0;
        else
            match <= comparison_result;
    end

endmodule

// Top-level module
module bank_pattern_matcher #(parameter W = 8, BANKS = 4) (
    input clk, rst_n,
    input [W-1:0] data,
    input [W-1:0] patterns [BANKS-1:0],
    input [$clog2(BANKS)-1:0] bank_sel,
    output match
);

    wire [W-1:0] selected_pattern;
    wire comparison_result;

    pattern_selector #(.W(W), .BANKS(BANKS)) u_pattern_selector (
        .clk(clk),
        .rst_n(rst_n),
        .patterns(patterns),
        .bank_sel(bank_sel),
        .selected_pattern(selected_pattern)
    );

    pattern_comparator #(.W(W)) u_pattern_comparator (
        .clk(clk),
        .rst_n(rst_n),
        .data(data),
        .selected_pattern(selected_pattern),
        .comparison_result(comparison_result)
    );

    output_register u_output_register (
        .clk(clk),
        .rst_n(rst_n),
        .comparison_result(comparison_result),
        .match(match)
    );

endmodule