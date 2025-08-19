//SystemVerilog
module TimeoutMatcher #(
    parameter WIDTH   = 8,
    parameter TIMEOUT = 100
)(
    input                  clk,
    input                  rst_n,
    input      [WIDTH-1:0] data,
    input      [WIDTH-1:0] pattern,
    output reg             timeout
);

    reg                match_detected;
    reg [15:0]         counter_value;
    reg                timeout_detected;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_detected   <= 1'b0;
            counter_value    <= 16'd0;
            timeout_detected <= 1'b0;
            timeout         <= 1'b0;
        end else begin
            match_detected   <= (data == pattern);
            counter_value    <= match_detected ? 16'd0 : (counter_value + 16'd1);
            timeout_detected <= (counter_value >= TIMEOUT);
            timeout         <= timeout_detected;
        end
    end
    
endmodule