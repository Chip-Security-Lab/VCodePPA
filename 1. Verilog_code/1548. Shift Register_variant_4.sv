//SystemVerilog
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
    
    // Pipelined control signal to distribute control logic load
    reg [STAGES-1:0] shift_pipe;

    // First stage processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_chain[0] <= '0;
            shift_pipe[0] <= 1'b0;
        end else begin
            shift_pipe[0] <= shift;
            if (shift) begin
                shift_chain[0] <= data_in;
            end
        end
    end
    
    // Middle and final stages with pipelined control signals
    genvar g;
    generate
        for (g = 1; g < STAGES; g++) begin : stage_gen
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    shift_chain[g] <= '0;
                    shift_pipe[g] <= 1'b0;
                end else begin
                    shift_pipe[g] <= shift_pipe[g-1];
                    shift_chain[g] <= shift_pipe[g-1] ? shift_chain[g-1] : shift_chain[g];
                end
            end
        end
    endgenerate
    
    // Last stage is the shadow output
    assign shadow_out = shift_chain[STAGES-1];
endmodule