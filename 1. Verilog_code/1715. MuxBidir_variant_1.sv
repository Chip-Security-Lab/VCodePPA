//SystemVerilog
module MuxBidir #(parameter W=8) (
    inout [W-1:0] bus_a,
    inout [W-1:0] bus_b,
    output [W-1:0] bus_out,
    input sel, oe
);

    // Internal signals
    reg [W-1:0] lut_result;
    wire [W-1:0] selected_input;
    
    // Input selection logic
    assign selected_input = sel ? bus_a : bus_b;
    
    // LUT implementation for subtraction assistance
    always @(*) begin
        case (selected_input)
            8'd0: lut_result = 8'd0;
            8'd1: lut_result = 8'd1;
            8'd2: lut_result = 8'd2;
            8'd3: lut_result = 8'd3;
            default: lut_result = selected_input;
        endcase
    end
    
    // Output assignment
    assign bus_out = lut_result;
    
    // Bus A control
    assign bus_a = (sel && oe) ? bus_out : 'bz;
    
    // Bus B control
    assign bus_b = (!sel && oe) ? bus_out : 'bz;
    
endmodule