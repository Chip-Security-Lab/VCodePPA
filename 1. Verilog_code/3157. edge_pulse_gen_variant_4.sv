//SystemVerilog
module edge_pulse_gen(
    input clk,
    input reset,
    input signal_in,
    output reg pulse_out
);
    reg signal_stage1;
    reg signal_stage2;
    reg signal_stage3;
    reg edge_detected_stage1;
    reg edge_detected_stage2;
    
    always @(posedge clk) begin
        signal_stage1 <= reset ? 1'b0 : signal_in;
        signal_stage2 <= reset ? 1'b0 : signal_stage1;
        signal_stage3 <= reset ? 1'b0 : signal_stage2;
        edge_detected_stage1 <= reset ? 1'b0 : (signal_stage1 & ~signal_stage2);
        edge_detected_stage2 <= reset ? 1'b0 : edge_detected_stage1;
        pulse_out <= reset ? 1'b0 : edge_detected_stage2;
    end
endmodule