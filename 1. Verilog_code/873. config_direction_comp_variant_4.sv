//SystemVerilog
module config_direction_comp #(parameter WIDTH = 8)(
    input clk, rst_n, 
    input direction,     // 0: MSB priority, 1: LSB priority
    input [WIDTH-1:0] data_in,
    input valid_in,      // 输入数据有效信号
    output valid_out,    // 输出数据有效信号
    output reg [$clog2(WIDTH)-1:0] priority_out
);
    // Stage 1: Input registration and data preparation
    reg [WIDTH-1:0] data_stage1;
    reg direction_stage1;
    reg valid_stage1;
    
    // Stage 2: Priority calculation - first half
    reg [WIDTH/2-1:0] priority_valid_high;
    reg [WIDTH/2-1:0] priority_valid_low;
    reg [($clog2(WIDTH)*WIDTH/2)-1:0] priority_index_high;
    reg [($clog2(WIDTH)*WIDTH/2)-1:0] priority_index_low;
    reg direction_stage2;
    reg valid_stage2;
    
    // Stage 3: Priority calculation - second half and selection
    reg [$clog2(WIDTH)-1:0] priority_high;
    reg [$clog2(WIDTH)-1:0] priority_low;
    reg has_priority_high;
    reg has_priority_low;
    reg direction_stage3;
    reg valid_stage3;
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            direction_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_stage1 <= data_in;
            direction_stage1 <= direction;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Split processing for high and low parts
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_valid_high <= 0;
            priority_valid_low <= 0;
            priority_index_high <= 0;
            priority_index_low <= 0;
            direction_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            direction_stage2 <= direction_stage1;
            
            // Process lower half bits
            for (i = 0; i < WIDTH/2; i = i + 1) begin
                priority_valid_low[i] <= data_stage1[i];
                priority_index_low[i*$clog2(WIDTH) +: $clog2(WIDTH)] <= i[$clog2(WIDTH)-1:0];
            end
            
            // Process upper half bits
            for (i = WIDTH/2; i < WIDTH; i = i + 1) begin
                priority_valid_high[i-WIDTH/2] <= data_stage1[i];
                priority_index_high[(i-WIDTH/2)*$clog2(WIDTH) +: $clog2(WIDTH)] <= i[$clog2(WIDTH)-1:0];
            end
        end
    end
    
    // Stage 3: Find priorities in each half
    integer j, k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_high <= 0;
            priority_low <= 0;
            has_priority_high <= 0;
            has_priority_low <= 0;
            direction_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            direction_stage3 <= direction_stage2;
            has_priority_high <= 0;
            has_priority_low <= 0;
            priority_high <= 0;
            priority_low <= 0;
            
            if (direction_stage2) begin // LSB priority
                // Low half
                for (j = 0; j < WIDTH/2; j = j + 1) begin
                    if (priority_valid_low[j] && !has_priority_low) begin
                        priority_low <= priority_index_low[j*$clog2(WIDTH) +: $clog2(WIDTH)];
                        has_priority_low <= 1;
                    end
                end
                
                // High half
                for (j = 0; j < WIDTH/2; j = j + 1) begin
                    if (priority_valid_high[j] && !has_priority_high) begin
                        priority_high <= priority_index_high[j*$clog2(WIDTH) +: $clog2(WIDTH)];
                        has_priority_high <= 1;
                    end
                end
            end else begin // MSB priority
                // High half
                for (k = WIDTH/2-1; k >= 0; k = k - 1) begin
                    if (priority_valid_high[k] && !has_priority_high) begin
                        priority_high <= priority_index_high[k*$clog2(WIDTH) +: $clog2(WIDTH)];
                        has_priority_high <= 1;
                    end
                end
                
                // Low half
                for (k = WIDTH/2-1; k >= 0; k = k - 1) begin
                    if (priority_valid_low[k] && !has_priority_low) begin
                        priority_low <= priority_index_low[k*$clog2(WIDTH) +: $clog2(WIDTH)];
                        has_priority_low <= 1;
                    end
                end
            end
        end
    end
    
    // Output stage: Final priority selection
    reg valid_output_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
            valid_output_reg <= 0;
        end else begin
            valid_output_reg <= valid_stage3;
            
            if (valid_stage3) begin
                if (direction_stage3) begin // LSB priority
                    if (has_priority_low)
                        priority_out <= priority_low;
                    else if (has_priority_high)
                        priority_out <= priority_high;
                    else
                        priority_out <= 0;
                end else begin // MSB priority
                    if (has_priority_high)
                        priority_out <= priority_high;
                    else if (has_priority_low)
                        priority_out <= priority_low;
                    else
                        priority_out <= 0;
                end
            end
        end
    end
    
    assign valid_out = valid_output_reg;
    
endmodule