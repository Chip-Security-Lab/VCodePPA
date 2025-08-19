//SystemVerilog
module feistel_network #(parameter HALF_WIDTH = 16) (
    input wire clk, rst_n, enable,
    input wire [HALF_WIDTH-1:0] left_in, right_in,
    input wire [HALF_WIDTH-1:0] round_key,
    output reg [HALF_WIDTH-1:0] left_out, right_out,
    output reg valid_out,
    input wire ready_in
);
    // Pipeline stage 1 registers - Input registration
    reg [HALF_WIDTH-1:0] left_stage1, right_stage1;
    reg [HALF_WIDTH-1:0] key_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers - First part of F function
    reg [HALF_WIDTH-1:0] left_stage2, right_stage2;
    reg [HALF_WIDTH-1:0] key_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers - Second part of F function
    reg [HALF_WIDTH-1:0] left_stage3, right_stage3;
    reg [HALF_WIDTH-1:0] f_result_part1_stage3;
    reg valid_stage3;
    
    // Pipeline stage 4 registers - F function completion
    reg [HALF_WIDTH-1:0] left_stage4, right_stage4;
    reg [HALF_WIDTH-1:0] f_result_stage4;
    reg valid_stage4;
    
    // F function computation split into parts
    wire [HALF_WIDTH/2-1:0] f_part1_upper, f_part1_lower;
    
    // Backpressure control
    wire stall = valid_out && !ready_in;
    wire pipeline_ready = !stall;
    
    // F function split into two parts for better timing
    assign f_part1_upper = right_stage2[HALF_WIDTH-1:HALF_WIDTH/2] ^ key_stage2[HALF_WIDTH-1:HALF_WIDTH/2];
    assign f_part1_lower = right_stage2[HALF_WIDTH/2-1:0] ^ key_stage2[HALF_WIDTH/2-1:0];
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_stage1 <= 0;
            right_stage1 <= 0;
            key_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (enable && pipeline_ready) begin
            left_stage1 <= left_in;
            right_stage1 <= right_in;
            key_stage1 <= round_key;
            valid_stage1 <= 1'b1;
        end else if (pipeline_ready) begin
            valid_stage1 <= 0;
        end
    end
    
    // Pipeline stage 2: Transfer data and prepare for F function
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_stage2 <= 0;
            right_stage2 <= 0;
            key_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (pipeline_ready) begin
            left_stage2 <= left_stage1;
            right_stage2 <= right_stage1;
            key_stage2 <= key_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Compute first part of F function
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_stage3 <= 0;
            right_stage3 <= 0;
            f_result_part1_stage3 <= 0;
            valid_stage3 <= 0;
        end else if (pipeline_ready) begin
            left_stage3 <= left_stage2;
            right_stage3 <= right_stage2;
            f_result_part1_stage3 <= {f_part1_upper, f_part1_lower};
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Pipeline stage 4: Complete F function computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_stage4 <= 0;
            right_stage4 <= 0;
            f_result_stage4 <= 0;
            valid_stage4 <= 0;
        end else if (pipeline_ready) begin
            left_stage4 <= left_stage3;
            right_stage4 <= right_stage3;
            f_result_stage4 <= f_result_part1_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Output stage: Perform final XOR and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_out <= 0;
            right_out <= 0;
            valid_out <= 0;
        end else if (pipeline_ready) begin
            left_out <= right_stage4;
            right_out <= left_stage4 ^ f_result_stage4;
            valid_out <= valid_stage4;
        end
    end
endmodule