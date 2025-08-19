//SystemVerilog
module variable_step_counter #(
    parameter STEP = 1
)(
    input  wire        clk,
    input  wire        rst,
    output reg  [7:0]  ring_reg
);
    // Internal pipeline registers to improve timing
    reg [7:0] rotation_stage1;
    reg [7:0] rotation_stage2;
    
    // Stage 1: Calculate rotation segments
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rotation_stage1 <= 8'h01;
        end else begin
            rotation_stage1 <= ring_reg;
        end
    end
    
    // Stage 2: Perform rotation operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rotation_stage2 <= 8'h01;
        end else begin
            rotation_stage2 <= {rotation_stage1[STEP-1:0], rotation_stage1[7:STEP]};
        end
    end
    
    // Output stage: Register final result
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ring_reg <= 8'h01;
        end else begin
            ring_reg <= rotation_stage2;
        end
    end
    
endmodule