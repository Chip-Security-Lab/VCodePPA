module shift_buffer #(
    parameter WIDTH = 8,
    parameter STAGES = 4
)(
    input wire clk,
    input wire enable,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] shift_reg [0:STAGES-1];
    integer i;
    
    always @(posedge clk) begin
        if (enable) begin
            shift_reg[0] <= data_in;
            for (i = 1; i < STAGES; i = i + 1)
                shift_reg[i] <= shift_reg[i-1];
        end
    end
    
    assign data_out = shift_reg[STAGES-1];
endmodule