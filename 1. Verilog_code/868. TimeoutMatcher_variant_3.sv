//SystemVerilog
module TimeoutMatcher #(parameter WIDTH=8, TIMEOUT=100) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg timeout
);
    reg [15:0] counter;
    reg match_detected;
    reg [15:0] next_counter;
    reg next_timeout;
    
    // First stage: Detect pattern match
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_detected <= 0;
        end else begin
            match_detected <= (data == pattern);
        end
    end
    
    // Second stage: Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
        end else begin
            counter <= match_detected ? 0 : counter + 1;
        end
    end
    
    // Third stage: Timeout detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout <= 0;
        end else begin
            timeout <= (counter >= TIMEOUT);
        end
    end
endmodule