module sample_hold_recovery (
    input wire clk,
    input wire sample_enable,
    input wire [11:0] analog_input,
    output reg [11:0] held_value,
    output reg hold_active
);
    always @(posedge clk) begin
        if (sample_enable) begin
            held_value <= analog_input;
            hold_active <= 1'b1;
        end else begin
            hold_active <= 1'b1; // Continue holding
        end
    end
endmodule