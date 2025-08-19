//SystemVerilog
module interrupt_timer #(parameter WIDTH = 32)(
    input clock, reset, enable,
    input [WIDTH-1:0] compare_val,
    output [WIDTH-1:0] count_out,
    output irq_out
);
    reg [WIDTH-1:0] counter;
    reg irq_pending;
    reg irq_out_reg;
    
    // Retimed combinational logic signals
    wire counter_match;
    wire irq_trigger;
    wire clear_pending;
    
    // Retimed combinational logic
    assign counter_match = (counter == compare_val);
    assign irq_trigger = irq_pending & ~irq_out_reg;
    assign clear_pending = irq_out_reg;
    assign count_out = counter;
    assign irq_out = irq_out_reg;
    
    // Retimed sequential logic block
    always @(posedge clock) begin
        if (reset) begin
            counter <= {WIDTH{1'b0}};
            irq_pending <= 1'b0;
            irq_out_reg <= 1'b0;
        end 
        else if (enable) begin
            // Counter update - retimed
            counter <= counter + 1'b1;
            
            // IRQ pending logic - retimed to be before combinational logic
            if (counter == compare_val) 
                irq_pending <= 1'b1;
            else if (irq_out_reg)
                irq_pending <= 1'b0;
                
            // IRQ output update - retimed
            irq_out_reg <= irq_pending & ~irq_out_reg;
        end
    end
endmodule