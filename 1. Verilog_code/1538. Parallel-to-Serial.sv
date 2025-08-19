module p2s_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] parallel_in,
    input wire load_parallel,
    input wire shift_en,
    output wire serial_out,
    output reg [WIDTH-1:0] shadow_data
);
    // Shift register
    reg [WIDTH-1:0] shift_reg;
    
    // Shift register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= 0;
        else if (load_parallel)
            shift_reg <= parallel_in;
        else if (shift_en)
            shift_reg <= {shift_reg[WIDTH-2:0], 1'b0};
    end
    
    // Serial output is MSB
    assign serial_out = shift_reg[WIDTH-1];
    
    // Shadow register captures parallel input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= 0;
        else if (load_parallel)
            shadow_data <= parallel_in;
    end
endmodule