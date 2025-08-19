//SystemVerilog
module decade_counter (
    input wire clk, reset,
    output reg [3:0] counter,
    output reg decade_pulse
);
    // Internal combinational signal for detecting count of 9
    wire count_is_nine;
    // Next state logic
    wire [3:0] next_counter;
    
    // Detect count of 9 with combinational logic
    assign count_is_nine = (counter == 4'd9);
    // Calculate next counter value
    assign next_counter = (count_is_nine || reset) ? 4'd0 : counter + 1'b1;
    
    // Combined sequential logic with same clock trigger
    always @(posedge clk) begin
        counter <= next_counter;
        decade_pulse <= count_is_nine;
    end
endmodule