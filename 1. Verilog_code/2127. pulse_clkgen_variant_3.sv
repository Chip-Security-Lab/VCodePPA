//SystemVerilog
module pulse_clkgen #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst,
    output reg pulse
);
    // Pipeline stage 1: Counter
    reg [WIDTH-1:0] delay_cnt_stage1;
    reg counter_max_stage1;
    
    // Pipeline stage 2: Pulse generation
    reg counter_max_stage2;
    
    // Counter reset logic
    always @(posedge clk) begin
        if (rst) begin
            delay_cnt_stage1 <= {WIDTH{1'b0}};
        end else begin
            delay_cnt_stage1 <= delay_cnt_stage1 + 1'b1;
        end
    end
    
    // Counter max detection logic
    always @(posedge clk) begin
        if (rst) begin
            counter_max_stage1 <= 1'b0;
        end else begin
            counter_max_stage1 <= (delay_cnt_stage1 == {WIDTH{1'b1}} - 1'b1) ? 1'b1 : 1'b0;
        end
    end
    
    // Pipeline register for comparison result
    always @(posedge clk) begin
        if (rst) begin
            counter_max_stage2 <= 1'b0;
        end else begin
            counter_max_stage2 <= counter_max_stage1;
        end
    end
    
    // Final pulse generation logic
    always @(posedge clk) begin
        if (rst) begin
            pulse <= 1'b0;
        end else begin
            pulse <= counter_max_stage2;
        end
    end
endmodule