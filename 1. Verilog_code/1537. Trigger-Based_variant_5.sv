//SystemVerilog
module trigger_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clock,
    input wire nreset,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] trigger_value,
    output reg [WIDTH-1:0] shadow_data
);
    // Pipeline stage - registered trigger value
    reg [WIDTH-1:0] trigger_value_reg;
    
    // Register the trigger value instead of input data
    always @(posedge clock or negedge nreset) begin
        if (~nreset)
            trigger_value_reg <= {WIDTH{1'b0}};
        else
            trigger_value_reg <= trigger_value;
    end
    
    // Capture to shadow when input data matches registered trigger value
    always @(posedge clock or negedge nreset) begin
        if (~nreset)
            shadow_data <= {WIDTH{1'b0}};
        else if (data_in == trigger_value_reg)
            shadow_data <= data_in;
    end
endmodule