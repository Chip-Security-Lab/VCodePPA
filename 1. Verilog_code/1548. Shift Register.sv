module shift_shadow_reg #(
    parameter WIDTH = 16,
    parameter STAGES = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire shift,
    output wire [WIDTH-1:0] shadow_out
);
    // Shift register chain
    reg [WIDTH-1:0] shift_chain [0:STAGES-1];
    
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < STAGES; i = i + 1)
                shift_chain[i] <= 0;
        end else if (shift) begin
            shift_chain[0] <= data_in;
            for (i = 1; i < STAGES; i = i + 1)
                shift_chain[i] <= shift_chain[i-1];
        end
    end
    
    // Last stage is the shadow output
    assign shadow_out = shift_chain[STAGES-1];
endmodule