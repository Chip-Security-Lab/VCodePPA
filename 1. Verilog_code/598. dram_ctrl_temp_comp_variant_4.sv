//SystemVerilog
module dram_ctrl_temp_comp #(
    parameter BASE_REFRESH = 7800
)(
    input clk,
    input rst_n,
    input [7:0] temperature,
    output reg refresh_req
);

    // Stage 1: Temperature scaling and refresh interval calculation
    reg [15:0] temp_scaled_stage1;
    reg [15:0] refresh_interval_stage1;
    reg valid_stage1;
    
    // Stage 2: Carry-save adder preparation
    reg [15:0] refresh_counter_stage2;
    reg [15:0] refresh_interval_stage2;
    reg [15:0] g_stage2;
    reg [15:0] p_stage2;
    reg valid_stage2;
    
    // Stage 3: Carry chain calculation
    reg [15:0] c_stage3;
    reg [15:0] p_stage3;
    reg valid_stage3;
    
    // Stage 4: Final sum and comparison
    reg [15:0] sum_stage4;
    reg [15:0] refresh_interval_stage4;
    reg valid_stage4;
    
    // Stage 1 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            temp_scaled_stage1 <= 0;
            refresh_interval_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            temp_scaled_stage1 <= {8'b0, temperature} << 3 + {8'b0, temperature} << 1;
            refresh_interval_stage1 <= BASE_REFRESH + temp_scaled_stage1;
            valid_stage1 <= 1;
        end
    end
    
    // Stage 2 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_counter_stage2 <= 0;
            refresh_interval_stage2 <= 0;
            g_stage2 <= 0;
            p_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1) begin
            refresh_counter_stage2 <= refresh_req ? 0 : sum_stage4;
            refresh_interval_stage2 <= refresh_interval_stage1;
            g_stage2 <= refresh_counter_stage2 & refresh_interval_stage2;
            p_stage2 <= refresh_counter_stage2 ^ refresh_interval_stage2;
            valid_stage2 <= 1;
        end else begin
            valid_stage2 <= 0;
        end
    end
    
    // Stage 3 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_stage3 <= 0;
            p_stage3 <= 0;
            valid_stage3 <= 0;
        end else if (valid_stage2) begin
            c_stage3[0] <= 1'b0;
            for (int i = 0; i < 15; i++) begin
                c_stage3[i+1] <= g_stage2[i] | (p_stage2[i] & c_stage3[i]);
            end
            p_stage3 <= p_stage2;
            valid_stage3 <= 1;
        end else begin
            valid_stage3 <= 0;
        end
    end
    
    // Stage 4 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage4 <= 0;
            refresh_interval_stage4 <= 0;
            valid_stage4 <= 0;
        end else if (valid_stage3) begin
            sum_stage4 <= p_stage3 ^ c_stage3;
            refresh_interval_stage4 <= refresh_interval_stage2;
            valid_stage4 <= 1;
        end else begin
            valid_stage4 <= 0;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_req <= 0;
        end else if (valid_stage4) begin
            refresh_req <= (sum_stage4 >= refresh_interval_stage4);
        end
    end

endmodule