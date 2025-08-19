//SystemVerilog
module duty_cycle_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire [2:0] duty_ratio,
    output wire clk_out
);
    reg [2:0] phase;
    reg enable;
    
    // Counter for tracking phase position
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            phase <= 3'd0;
        end
        else if (phase == 3'd7) begin
            phase <= 3'd0;
        end
        else begin
            phase <= phase + 1'b1;
        end
    end
    
    // Pre-compute enable signal to improve timing
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable <= 1'b0;
        end
        else if (phase == 3'd7 && duty_ratio > 3'd0) begin
            enable <= 1'b1;
        end
        else if (phase == 3'd7 && duty_ratio == 3'd0) begin
            enable <= 1'b0;
        end
        else if ((phase + 1'b1) < duty_ratio) begin
            enable <= 1'b1;
        end
        else begin
            enable <= 1'b0;
        end
    end
    
    // Implement clock gating with registered enable to reduce glitches
    assign clk_out = clk_in & enable;
endmodule