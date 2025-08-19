//SystemVerilog
module cam_10 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [15:0] wide_data_in,
    output reg wide_match,
    output reg [15:0] wide_store_data
);

    // Pipeline stage 1: Input register and write control
    reg [15:0] data_in_stage1;
    reg write_en_stage1;
    
    // Pipeline stage 2: Data storage and comparison
    reg [15:0] store_data_stage2;
    reg [15:0] compare_data_stage2;
    reg write_en_stage2;
    
    // Pipeline stage 3: Match result generation
    reg match_result_stage3;

    // Stage 1: Input data registration
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage1 <= 16'b0;
        end else begin
            data_in_stage1 <= wide_data_in;
        end
    end

    // Stage 1: Write enable registration
    always @(posedge clk) begin
        if (rst) begin
            write_en_stage1 <= 1'b0;
        end else begin
            write_en_stage1 <= write_en;
        end
    end

    // Stage 2: Write enable propagation
    always @(posedge clk) begin
        if (rst) begin
            write_en_stage2 <= 1'b0;
        end else begin
            write_en_stage2 <= write_en_stage1;
        end
    end

    // Stage 2: Data storage
    always @(posedge clk) begin
        if (rst) begin
            store_data_stage2 <= 16'b0;
        end else if (write_en_stage1) begin
            store_data_stage2 <= data_in_stage1;
        end
    end

    // Stage 2: Comparison data preparation
    always @(posedge clk) begin
        if (rst) begin
            compare_data_stage2 <= 16'b0;
        end else begin
            compare_data_stage2 <= data_in_stage1;
        end
    end

    // Stage 3: Match calculation
    always @(posedge clk) begin
        if (rst) begin
            match_result_stage3 <= 1'b0;
        end else begin
            match_result_stage3 <= (store_data_stage2 == compare_data_stage2);
        end
    end

    // Output stage: Store data
    always @(posedge clk) begin
        if (rst) begin
            wide_store_data <= 16'b0;
        end else begin
            wide_store_data <= store_data_stage2;
        end
    end

    // Output stage: Match signal
    always @(posedge clk) begin
        if (rst) begin
            wide_match <= 1'b0;
        end else begin
            wide_match <= match_result_stage3;
        end
    end

endmodule