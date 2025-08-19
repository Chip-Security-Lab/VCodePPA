//SystemVerilog - IEEE 1364-2005
module windowed_signal_recovery #(
    parameter DATA_WIDTH = 10,
    parameter WINDOW_SIZE = 5
)(
    input wire clk,
    input wire rst,
    input wire window_enable,
    input wire [DATA_WIDTH-1:0] signal_in,
    output reg [DATA_WIDTH-1:0] signal_out,
    output reg valid
);
    // Pipeline stage 1: Window storage
    reg [DATA_WIDTH-1:0] window_stage1 [0:WINDOW_SIZE-1];
    reg valid_stage1;
    
    // Pipeline stage 2: Sum calculation
    reg [DATA_WIDTH+3:0] partial_sum_stage2 [0:(WINDOW_SIZE/2)];
    reg valid_stage2;
    
    // Pipeline stage 3: Final sum and division
    reg [DATA_WIDTH+3:0] total_sum_stage3;
    reg valid_stage3;
    
    integer i, j;
    
    // Pipeline stage 1: Shift window and input capture
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < WINDOW_SIZE; i = i+1)
                window_stage1[i] <= 0;
            valid_stage1 <= 1'b0;
        end else begin
            if (window_enable) begin
                // Shift window values
                for (i = WINDOW_SIZE-1; i > 0; i = i-1)
                    window_stage1[i] <= window_stage1[i-1];
                window_stage1[0] <= signal_in;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 2: Partial sum calculations
    always @(posedge clk) begin
        if (rst) begin
            for (j = 0; j <= (WINDOW_SIZE/2); j = j+1)
                partial_sum_stage2[j] <= 0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                // Divide the summation work into smaller chunks
                for (j = 0; j < (WINDOW_SIZE/2); j = j+1)
                    partial_sum_stage2[j] <= window_stage1[j*2] + window_stage1[j*2+1];
                
                // Handle odd WINDOW_SIZE case
                if (WINDOW_SIZE % 2 == 1)
                    partial_sum_stage2[WINDOW_SIZE/2] <= window_stage1[WINDOW_SIZE-1];
                else
                    partial_sum_stage2[WINDOW_SIZE/2] <= 0;
                    
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 3: Final summation and division
    always @(posedge clk) begin
        if (rst) begin
            total_sum_stage3 <= 0;
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                // Sum all partial sums
                total_sum_stage3 <= 0;
                for (i = 0; i <= (WINDOW_SIZE/2); i = i+1)
                    total_sum_stage3 <= total_sum_stage3 + partial_sum_stage2[i];
                
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // Output stage: Division and result capture
    always @(posedge clk) begin
        if (rst) begin
            signal_out <= 0;
            valid <= 1'b0;
        end else begin
            if (valid_stage3) begin
                signal_out <= total_sum_stage3 / WINDOW_SIZE;
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end
endmodule