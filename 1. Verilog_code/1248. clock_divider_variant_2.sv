//SystemVerilog
//IEEE 1364-2005 Verilog Standard
module clock_divider #(parameter DIVIDE_BY = 2) (
    input wire clk_in, reset,
    output reg clk_out
);
    localparam WIDTH = $clog2(DIVIDE_BY);
    
    // Threshold value - when to toggle clock
    wire [WIDTH-1:0] threshold = DIVIDE_BY/2 - 1;
    
    // Count register - moved closer to data source
    reg [WIDTH-1:0] count;
    reg valid;
    wire terminal_count;
    
    // Final stage signals
    reg toggle_pending;
    
    // Generate borrow signals for decrementing from target value
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] decrement_result;
    
    assign borrow[0] = 1'b1; // Initial borrow-in is 1 (always decrement)
    
    // Implement borrow lookahead logic
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow
            assign decrement_result[i] = threshold[i] ^ borrow[i];
            assign borrow[i+1] = (~threshold[i]) & borrow[i];
        end
    endgenerate
    
    // Terminal count detection using threshold comparison
    assign terminal_count = (count == threshold);
    
    // Count management - single stage
    always @(posedge clk_in) begin
        if (reset) begin
            count <= {WIDTH{1'b0}};
            valid <= 1'b0;
            toggle_pending <= 1'b0;
        end else begin
            if (terminal_count) begin
                count <= {WIDTH{1'b0}};
                toggle_pending <= valid; // Only toggle if valid
            end else begin
                count <= count + 1'b1;
                toggle_pending <= 1'b0;
            end
            valid <= 1'b1;
        end
    end
    
    // Clock output logic - moved forward with logic merged
    always @(posedge clk_in) begin
        if (reset) begin
            clk_out <= 1'b0;
        end else if (toggle_pending) begin
            clk_out <= ~clk_out;
        end
    end
endmodule