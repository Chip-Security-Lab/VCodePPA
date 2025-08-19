module reset_monitor(
    input wire clk,
    input wire [3:0] reset_inputs,
    output reg [3:0] reset_outputs,
    output reg [3:0] reset_status
);
    always @(posedge clk) begin
        reset_outputs <= reset_inputs;
        reset_status <= reset_inputs;  // Track which resets were activated
    end
endmodule