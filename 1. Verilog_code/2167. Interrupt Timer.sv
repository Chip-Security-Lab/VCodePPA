module interrupt_timer #(parameter WIDTH = 32)(
    input clock, reset, enable,
    input [WIDTH-1:0] compare_val,
    output [WIDTH-1:0] count_out,
    output reg irq_out
);
    reg [WIDTH-1:0] counter;
    reg irq_pending;
    always @(posedge clock) begin
        if (reset) begin
            counter <= {WIDTH{1'b0}}; irq_pending <= 1'b0; irq_out <= 1'b0;
        end else if (enable) begin
            counter <= counter + 1'b1;
            if (counter == compare_val) irq_pending <= 1'b1;
            irq_out <= irq_pending & ~irq_out;
            if (irq_out) irq_pending <= 1'b0;
        end
    end
    assign count_out = counter;
endmodule