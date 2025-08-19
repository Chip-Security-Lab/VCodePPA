//SystemVerilog
module TimerSync #(parameter WIDTH=16) (
    input clk, rst_n, enable,
    output reg timer_out
);
    reg [WIDTH-1:0] counter;
    wire counter_max = &counter; // Use reduction operator for better efficiency
    wire [WIDTH-1:0] next_counter = counter_max ? {WIDTH{1'b0}} : counter + 1'b1;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= {WIDTH{1'b0}};
            timer_out <= 1'b0;
        end else if (enable) begin
            counter <= next_counter;
            timer_out <= counter_max;
        end
    end
endmodule