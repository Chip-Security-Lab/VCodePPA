module duty_cycle_clock #(
    parameter WIDTH = 8
)(
    input wire clkin,
    input wire reset,
    input wire [WIDTH-1:0] high_time,
    input wire [WIDTH-1:0] low_time,
    output reg clkout
);
    reg [WIDTH-1:0] counter = 0;
    
    always @(posedge clkin or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clkout <= 0;
        end else begin
            if (clkout == 0) begin
                if (counter >= low_time) begin
                    counter <= 0;
                    clkout <= 1;
                end else counter <= counter + 1;
            end else begin
                if (counter >= high_time) begin
                    counter <= 0;
                    clkout <= 0;
                end else counter <= counter + 1;
            end
        end
    end
endmodule