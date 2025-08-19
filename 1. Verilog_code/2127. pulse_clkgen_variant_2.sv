//SystemVerilog
module pulse_clkgen #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst,
    output reg pulse
);
    // Pipeline registers for counter and comparison stages
    reg [WIDTH-1:0] delay_cnt_stage1;
    reg [WIDTH-1:0] target_value;
    reg comparison_stage2;
    reg pulse_stage3;
    
    // Reset logic
    always @(posedge clk) begin
        if (rst) begin
            delay_cnt_stage1 <= {WIDTH{1'b0}};
            target_value <= {WIDTH{1'b1}};
            comparison_stage2 <= 1'b0;
            pulse_stage3 <= 1'b0;
            pulse <= 1'b0;
        end
    end
    
    // Counter incrementing logic
    always @(posedge clk) begin
        if (!rst) begin
            delay_cnt_stage1 <= delay_cnt_stage1 + 1'b1;
        end
    end
    
    // Comparison operation logic
    always @(posedge clk) begin
        if (!rst) begin
            comparison_stage2 <= (delay_cnt_stage1 == target_value);
        end
    end
    
    // Pulse stage 3 generation
    always @(posedge clk) begin
        if (!rst) begin
            pulse_stage3 <= comparison_stage2;
        end
    end
    
    // Final output pulse generation
    always @(posedge clk) begin
        if (!rst) begin
            pulse <= pulse_stage3;
        end
    end
endmodule