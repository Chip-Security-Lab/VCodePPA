//SystemVerilog
module basic_ring_counter #(parameter WIDTH = 4)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [WIDTH-1:0] count,
    output reg count_valid
);
    // Pipeline registers for each stage
    reg [WIDTH-1:0] count_stage1, count_stage2;
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Calculate the rotation
    wire [WIDTH-1:0] rotated_count;
    assign rotated_count = {count[WIDTH-2:0], count[WIDTH-1]};
    
    // Initialize with one-hot encoding
    initial begin
        count = {{(WIDTH-1){1'b0}}, 1'b1};
        count_valid = 1'b0;
        count_stage1 = {{(WIDTH-1){1'b0}}, 1'b1};
        count_stage2 = {{(WIDTH-1){1'b0}}, 1'b1};
        valid_stage1 = 1'b0;
        valid_stage2 = 1'b0;
    end
    
    // Stage 1: Handle the first pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage1 <= {{(WIDTH-1){1'b0}}, 1'b1};
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            count_stage1 <= rotated_count;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Handle the second pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage2 <= {{(WIDTH-1){1'b0}}, 1'b1};
            valid_stage2 <= 1'b0;
        end else begin
            count_stage2 <= count_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage: Update the final output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= {{(WIDTH-1){1'b0}}, 1'b1};
            count_valid <= 1'b0;
        end else begin
            count <= count_stage2;
            count_valid <= valid_stage2;
        end
    end
endmodule