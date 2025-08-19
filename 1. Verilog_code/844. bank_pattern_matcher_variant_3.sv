//SystemVerilog
// Pattern comparison submodule
module pattern_comparator #(parameter W = 8) (
    input [W-1:0] data,
    input [W-1:0] pattern,
    output reg match_result
);
    always @(*) begin
        match_result = (data == pattern);
    end
endmodule

// Synchronization submodule
module match_synchronizer (
    input clk, rst_n,
    input pattern_match,
    output reg match
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match <= 1'b0;
        else
            match <= pattern_match;
    end
endmodule

// Pattern selector submodule
module pattern_selector #(parameter W = 8, BANKS = 4) (
    input [W-1:0] patterns [BANKS-1:0],
    input [$clog2(BANKS)-1:0] bank_sel,
    output [W-1:0] selected_pattern
);
    assign selected_pattern = patterns[bank_sel];
endmodule

// Top-level module
module bank_pattern_matcher #(parameter W = 8, BANKS = 4) (
    input clk, rst_n,
    input [W-1:0] data,
    input [W-1:0] patterns [BANKS-1:0],
    input [$clog2(BANKS)-1:0] bank_sel,
    output match
);
    // Internal signals
    wire [W-1:0] selected_pattern;
    wire pattern_match;
    
    // Instantiate submodules
    pattern_selector #(.W(W), .BANKS(BANKS)) selector (
        .patterns(patterns),
        .bank_sel(bank_sel),
        .selected_pattern(selected_pattern)
    );
    
    pattern_comparator #(.W(W)) comparator (
        .data(data),
        .pattern(selected_pattern),
        .match_result(pattern_match)
    );
    
    match_synchronizer synchronizer (
        .clk(clk),
        .rst_n(rst_n),
        .pattern_match(pattern_match),
        .match(match)
    );
endmodule