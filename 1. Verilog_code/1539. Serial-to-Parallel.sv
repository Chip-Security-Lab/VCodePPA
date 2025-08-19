module s2p_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire serial_in,
    input wire shift_en,
    input wire capture,
    output reg [WIDTH-1:0] shadow_out,
    output wire [WIDTH-1:0] parallel_out
);
    // Shift register for serial-to-parallel conversion
    reg [WIDTH-1:0] shift_reg;
    
    // Shift register operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= 0;
        else if (shift_en)
            shift_reg <= {shift_reg[WIDTH-2:0], serial_in};
    end
    
    // Parallel output directly from shift register
    assign parallel_out = shift_reg;
    
    // Shadow register captures parallel data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= 0;
        else if (capture)
            shadow_out <= shift_reg;
    end
endmodule