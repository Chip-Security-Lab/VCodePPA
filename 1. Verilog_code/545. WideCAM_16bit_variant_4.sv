//SystemVerilog
module cam_5 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [15:0] input_data,
    output reg match,
    output reg [15:0] stored_data
);

    // Stage 1: Input buffering
    reg write_en_stage1;
    reg [15:0] input_data_stage1;
    reg rst_stage1;
    
    always @(posedge clk) begin
        rst_stage1 <= rst;
        write_en_stage1 <= write_en;
        input_data_stage1 <= input_data;
    end
    
    // Stage 2: Data storage
    reg write_en_stage2;
    reg [15:0] input_data_stage2;
    reg rst_stage2;
    reg [15:0] stored_data_stage2;
    
    always @(posedge clk) begin
        rst_stage2 <= rst_stage1;
        write_en_stage2 <= write_en_stage1;
        input_data_stage2 <= input_data_stage1;
        
        if (rst_stage1) begin
            stored_data_stage2 <= 16'b0;
        end else if (write_en_stage1) begin
            stored_data_stage2 <= input_data_stage1;
        end
    end

    // Stage 3: Match detection preparation
    reg write_en_stage3;
    reg [15:0] input_data_stage3;
    reg rst_stage3;
    reg [15:0] stored_data_stage3;
    
    always @(posedge clk) begin
        rst_stage3 <= rst_stage2;
        write_en_stage3 <= write_en_stage2;
        input_data_stage3 <= input_data_stage2;
        stored_data_stage3 <= stored_data_stage2;
    end

    // Stage 4: Match detection
    reg match_stage4;
    
    always @(posedge clk) begin
        if (rst_stage3) begin
            match_stage4 <= 1'b0;
        end else if (!write_en_stage3) begin
            match_stage4 <= (stored_data_stage3 == input_data_stage3);
        end
    end

    // Stage 5: Output buffering
    always @(posedge clk) begin
        stored_data <= stored_data_stage3;
        match <= match_stage4;
    end

endmodule