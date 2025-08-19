//SystemVerilog
module cam_7 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire write_high,
    input wire [7:0] data_in,
    output reg match,
    output reg [7:0] priority_data
);

    // Stage 1: Input registers
    reg [7:0] data_in_stage1;
    reg write_en_stage1;
    reg write_high_stage1;
    
    // Stage 2: Priority registers
    reg [7:0] high_priority_stage2, low_priority_stage2;
    reg [7:0] data_in_stage2;
    reg write_en_stage2;
    reg write_high_stage2;
    
    // Stage 3: Match detection
    reg high_match_stage3, low_match_stage3;
    reg [7:0] high_priority_stage3, low_priority_stage3;
    reg [7:0] data_in_stage3;
    
    // Stage 4: Output selection
    reg high_match_stage4, low_match_stage4;
    reg [7:0] high_priority_stage4, low_priority_stage4;

    // Stage 1: Input registration - Data path
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage1 <= 8'b0;
        end else begin
            data_in_stage1 <= data_in;
        end
    end

    // Stage 1: Input registration - Control signals
    always @(posedge clk) begin
        if (rst) begin
            write_en_stage1 <= 1'b0;
            write_high_stage1 <= 1'b0;
        end else begin
            write_en_stage1 <= write_en;
            write_high_stage1 <= write_high;
        end
    end
    
    // Stage 2: Data propagation
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage2 <= 8'b0;
            write_en_stage2 <= 1'b0;
            write_high_stage2 <= 1'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            write_en_stage2 <= write_en_stage1;
            write_high_stage2 <= write_high_stage1;
        end
    end

    // Stage 2: Priority storage
    always @(posedge clk) begin
        if (rst) begin
            high_priority_stage2 <= 8'b0;
            low_priority_stage2 <= 8'b0;
        end else if (write_en_stage1) begin
            if (write_high_stage1)
                high_priority_stage2 <= data_in_stage1;
            else
                low_priority_stage2 <= data_in_stage1;
        end
    end
    
    // Stage 3: Data propagation
    always @(posedge clk) begin
        if (rst) begin
            high_priority_stage3 <= 8'b0;
            low_priority_stage3 <= 8'b0;
            data_in_stage3 <= 8'b0;
        end else begin
            high_priority_stage3 <= high_priority_stage2;
            low_priority_stage3 <= low_priority_stage2;
            data_in_stage3 <= data_in_stage2;
        end
    end

    // Stage 3: Match detection
    always @(posedge clk) begin
        if (rst) begin
            high_match_stage3 <= 1'b0;
            low_match_stage3 <= 1'b0;
        end else if (!write_en_stage2) begin
            high_match_stage3 <= (high_priority_stage2 == data_in_stage2);
            low_match_stage3 <= (low_priority_stage2 == data_in_stage2);
        end
    end
    
    // Stage 4: Data propagation
    always @(posedge clk) begin
        if (rst) begin
            high_priority_stage4 <= 8'b0;
            low_priority_stage4 <= 8'b0;
        end else begin
            high_priority_stage4 <= high_priority_stage3;
            low_priority_stage4 <= low_priority_stage3;
        end
    end

    // Stage 4: Match propagation
    always @(posedge clk) begin
        if (rst) begin
            high_match_stage4 <= 1'b0;
            low_match_stage4 <= 1'b0;
        end else begin
            high_match_stage4 <= high_match_stage3;
            low_match_stage4 <= low_match_stage3;
        end
    end
    
    // Final output stage: Match detection
    always @(posedge clk) begin
        if (rst) begin
            match <= 1'b0;
        end else begin
            match <= high_match_stage4 | low_match_stage4;
        end
    end

    // Final output stage: Priority data selection
    always @(posedge clk) begin
        if (rst) begin
            priority_data <= 8'b0;
        end else begin
            if (high_match_stage4)
                priority_data <= high_priority_stage4;
            else if (low_match_stage4)
                priority_data <= low_priority_stage4;
            else
                priority_data <= priority_data;
        end
    end

endmodule