//SystemVerilog
module pwm_div #(parameter HIGH=3, LOW=5) (
    input clk, rst_n,
    output reg out
);
    localparam PERIOD = HIGH + LOW;
    localparam COUNT_MAX = PERIOD - 1;
    localparam WIDTH = $clog2(PERIOD);
    
    reg [WIDTH-1:0] cnt;
    wire period_end = (cnt == COUNT_MAX);
    
    // Main counter with optimized bit width
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt <= {WIDTH{1'b0}};
        end else begin
            cnt <= period_end ? {WIDTH{1'b0}} : cnt + 1'b1;
        end
    end
    
    // Output generation with direct counter comparison
    always @(posedge clk) begin
        if (!rst_n) begin
            out <= 1'b0;
        end else begin
            // Using range check for cleaner logic
            out <= (cnt < HIGH);
        end
    end
endmodule