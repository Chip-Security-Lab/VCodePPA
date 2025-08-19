//SystemVerilog
module wave5_triangle #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    // Stage 1 registers - calculate next value
    reg [WIDTH-1:0] next_value_stage1;
    reg             direction_stage1;
    reg             valid_stage1;
    
    // Stage 2 registers - update direction
    reg [WIDTH-1:0] next_value_stage2;
    reg             direction_stage2;
    reg             valid_stage2;
    
    // Combinational logic for stage 1
    wire [WIDTH-1:0] incremented_value = wave_out + 1'b1;
    wire [WIDTH-1:0] decremented_value = wave_out - 1'b1;
    wire reached_max = (wave_out == {WIDTH{1'b1}});
    wire reached_min = (wave_out == {WIDTH{1'b0}});
    
    // Stage 1: Calculate next value based on current direction
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            next_value_stage1 <= 0;
            direction_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            direction_stage1 <= direction_stage2;
            
            if (direction_stage2)
                next_value_stage1 <= incremented_value;
            else
                next_value_stage1 <= decremented_value;
        end
    end
    
    // Stage 2: Determine direction change
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            next_value_stage2 <= 0;
            direction_stage2 <= 1'b1;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            next_value_stage2 <= next_value_stage1;
            
            // Update direction based on bounds
            if (reached_max)
                direction_stage2 <= 1'b0;
            else if (reached_min)
                direction_stage2 <= 1'b1;
            else
                direction_stage2 <= direction_stage1;
        end
    end
    
    // Final output stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wave_out <= 0;
        end else if (valid_stage2) begin
            wave_out <= next_value_stage2;
        end
    end
endmodule