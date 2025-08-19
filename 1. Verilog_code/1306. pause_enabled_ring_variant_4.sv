//SystemVerilog
// SystemVerilog
module pause_enabled_ring (
    input clk, pause, rst,
    output reg [3:0] current_state
);
    // Internal registers for the pipeline stages
    reg [3:0] current_state_reg;
    reg pause_reg;
    reg [3:0] intermediate_state;
    
    // First pipeline stage: register inputs
    always @(posedge clk) begin
        if (rst) begin
            current_state_reg <= 4'b0001;
            pause_reg <= 1'b0;
        end else begin
            current_state_reg <= current_state;
            pause_reg <= pause;
        end
    end
    
    // Second pipeline stage: compute intermediate state - split the combinational logic
    always @(posedge clk) begin
        if (rst) begin
            intermediate_state <= 4'b0001;
        end else begin
            intermediate_state <= (!pause_reg) ? {current_state_reg[0], current_state_reg[3:1]} : current_state_reg;
        end
    end
    
    // Final stage: update output register
    always @(posedge clk) begin
        if (rst) begin
            current_state <= 4'b0001;
        end else begin
            current_state <= intermediate_state;
        end
    end
endmodule