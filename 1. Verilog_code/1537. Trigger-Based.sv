module trigger_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clock,
    input wire nreset,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] trigger_value,
    output reg [WIDTH-1:0] shadow_data
);
    // Working register
    reg [WIDTH-1:0] working_reg;
    
    // Update working register
    always @(posedge clock or negedge nreset) begin
        if (~nreset)
            working_reg <= {WIDTH{1'b0}};
        else
            working_reg <= data_in;
    end
    
    // Capture to shadow when data matches trigger value
    always @(posedge clock or negedge nreset) begin
        if (~nreset)
            shadow_data <= {WIDTH{1'b0}};
        else if (working_reg == trigger_value)
            shadow_data <= working_reg;
    end
endmodule