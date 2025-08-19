//SystemVerilog
// IEEE 1364-2005 Verilog标准
module trigger_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clock,
    input wire nreset,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] trigger_value,
    output reg [WIDTH-1:0] shadow_data
);
    // Working register placed directly at input
    reg [WIDTH-1:0] working_reg;
    
    // Trigger detection signal
    wire trigger_detected;
    assign trigger_detected = (data_in == trigger_value);
    
    // Register the trigger detection signal
    reg trigger_detected_reg;
    
    always @(posedge clock or negedge nreset) begin
        if (~nreset) begin
            working_reg <= {WIDTH{1'b0}};
            trigger_detected_reg <= 1'b0;
            shadow_data <= {WIDTH{1'b0}};
        end
        else begin
            working_reg <= data_in;
            trigger_detected_reg <= trigger_detected;
            
            if (trigger_detected_reg)
                shadow_data <= working_reg;
        end
    end
endmodule