//SystemVerilog
module sync_comb_filter #(
    parameter W = 12,
    parameter DELAY = 8
)(
    input clk, rst_n, enable,
    input [W-1:0] din,
    output reg [W-1:0] dout,
    output reg valid_out
);
    // Pipeline stage registers - increased pipeline depth
    reg [W-1:0] din_stage1, din_stage2, din_stage3;
    reg [W-1:0] delay_value_stage1, delay_value_stage2, delay_value_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Delay line memory
    reg [W-1:0] delay_line [DELAY-1:0];
    
    integer i;
    
    // Stage 0: Input registration and delay line management
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < DELAY; i = i + 1)
                delay_line[i] <= 0;
            din_stage1 <= 0;
            delay_value_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            if (enable) begin
                // Register input for stage 1
                din_stage1 <= din;
                
                // Read delay value before shifting
                delay_value_stage1 <= delay_line[DELAY-1];
                
                // Shift delay line (always happens when enabled)
                for (i = DELAY-1; i > 0; i = i - 1)
                    delay_line[i] <= delay_line[i-1];
                delay_line[0] <= din;
                
                // Propagate valid signal
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 1: Intermediate pipeline stage for timing improvement
    always @(posedge clk) begin
        if (!rst_n) begin
            din_stage2 <= 0;
            delay_value_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            din_stage2 <= din_stage1;
            delay_value_stage2 <= delay_value_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 2: Additional pipeline stage for timing improvement
    always @(posedge clk) begin
        if (!rst_n) begin
            din_stage3 <= 0;
            delay_value_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            din_stage3 <= din_stage2;
            delay_value_stage3 <= delay_value_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 3: Perform subtraction operation and generate output
    always @(posedge clk) begin
        if (!rst_n) begin
            dout <= 0;
            valid_out <= 0;
        end else begin
            if (valid_stage3) begin
                // Compute filter output: y[n] = x[n] - x[n-DELAY]
                dout <= din_stage3 - delay_value_stage3;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule