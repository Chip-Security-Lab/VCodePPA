module capture_compare_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire capture_trig,
    input wire [WIDTH-1:0] compare_val,
    output reg compare_match,
    output reg [WIDTH-1:0] capture_val
);
    reg [WIDTH-1:0] counter;
    reg capture_trig_prev;
    
    always @(posedge clk) begin
        if (rst) begin
            counter <= {WIDTH{1'b0}};
            compare_match <= 1'b0;
            capture_val <= {WIDTH{1'b0}};
            capture_trig_prev <= 1'b0;
        end else begin
            counter <= counter + 1'b1;
            capture_trig_prev <= capture_trig;
            
            if (counter == compare_val) begin
                compare_match <= 1'b1;
            end else begin
                compare_match <= 1'b0;
            end
            
            if (capture_trig && !capture_trig_prev) begin
                capture_val <= counter;
            end
        end
    end
endmodule