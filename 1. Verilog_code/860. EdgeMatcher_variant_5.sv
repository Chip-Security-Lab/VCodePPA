//SystemVerilog
module EdgeMatcher #(
    parameter WIDTH = 8
)(
    input                  clk,
    input      [WIDTH-1:0] data_in,
    input      [WIDTH-1:0] pattern,
    output                 edge_match
);

    // Pipeline stage signals
    wire [WIDTH-1:0] data_pipe;
    wire [WIDTH-1:0] pattern_pipe;
    wire            match_pipe;
    wire            edge_pipe;

    // Pipeline stage 1: Input registration
    reg [WIDTH-1:0] data_reg;
    reg [WIDTH-1:0] pattern_reg;
    
    always @(posedge clk) begin
        data_reg    <= data_in;
        pattern_reg <= pattern;
    end

    // Pipeline stage 2: Pattern matching
    reg match_result;
    always @(posedge clk) begin
        match_result <= (data_reg == pattern_reg);
    end

    // Pipeline stage 3: Edge detection
    reg match_prev;
    reg edge_detected;
    always @(posedge clk) begin
        match_prev    <= match_result;
        edge_detected <= match_result && !match_prev;
    end

    // Output assignment
    assign edge_match = edge_detected;

endmodule