//SystemVerilog
module multistage_priority_comp #(parameter WIDTH = 16, STAGES = 3)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input valid_in,
    output reg valid_out,
    output reg [$clog2(WIDTH)-1:0] priority_out
);
    // Define stage width
    localparam STAGE_WIDTH = WIDTH / STAGES;
    
    // Pipeline stage 1: Find priority within each segment
    reg [$clog2(STAGE_WIDTH)-1:0] segment_priority [0:STAGES-1];
    reg [STAGES-1:0] segment_valid;
    reg [WIDTH-1:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Process segments and prepare for final selection
    reg [$clog2(STAGE_WIDTH)-1:0] segment_priority_stage2 [0:STAGES-1];
    reg [STAGES-1:0] segment_valid_stage2;
    reg valid_stage2;
    
    // Stage 1: Segment priority detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer s = 0; s < STAGES; s = s + 1) begin
                segment_priority[s] <= 0;
                segment_valid[s] <= 0;
            end
            data_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_stage1 <= data_in;
            valid_stage1 <= valid_in;
            
            // Process each segment in parallel
            for (integer s = 0; s < STAGES; s = s + 1) begin
                segment_valid[s] <= 0;
                segment_priority[s] <= 0;
                
                // Find priority in current segment
                for (integer i = STAGE_WIDTH-1; i >= 0; i = i - 1) begin
                    if (data_in[s*STAGE_WIDTH + i]) begin
                        segment_valid[s] <= 1;
                        segment_priority[s] <= i[$clog2(STAGE_WIDTH)-1:0];
                    end
                end
            end
        end
    end
    
    // Stage 2: Prepare for final priority selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer s = 0; s < STAGES; s = s + 1) begin
                segment_priority_stage2[s] <= 0;
                segment_valid_stage2[s] <= 0;
            end
            valid_stage2 <= 0;
        end else begin
            // Pass through to stage 2
            for (integer s = 0; s < STAGES; s = s + 1) begin
                segment_priority_stage2[s] <= segment_priority[s];
                segment_valid_stage2[s] <= segment_valid[s];
            end
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Final priority resolution
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_stage2;
            
            // Default assignment
            priority_out <= 0;
            
            // Find highest priority stage
            for (integer s = STAGES-1; s >= 0; s = s - 1) begin
                if (segment_valid_stage2[s])
                    priority_out <= {s[$clog2(STAGES)-1:0], 
                                    segment_priority_stage2[s]};
            end
        end
    end
endmodule