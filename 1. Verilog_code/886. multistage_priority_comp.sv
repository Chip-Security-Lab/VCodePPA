module multistage_priority_comp #(parameter WIDTH = 16, STAGES = 3)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out
);
    // Define stage width
    localparam STAGE_WIDTH = WIDTH / STAGES;
    
    reg [$clog2(STAGE_WIDTH)-1:0] stage_priority [0:STAGES-1];
    reg [STAGES-1:0] stage_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
            for (integer s = 0; s < STAGES; s = s + 1) begin
                stage_priority[s] <= 0;
                stage_valid[s] <= 0;
            end
        end else begin
            // Process each stage
            for (integer s = 0; s < STAGES; s = s + 1) begin
                stage_valid[s] <= 0;
                stage_priority[s] <= 0;
                
                // Find priority in current segment
                for (integer i = STAGE_WIDTH-1; i >= 0; i = i - 1) begin
                    if (data_in[s*STAGE_WIDTH + i]) begin
                        stage_valid[s] <= 1;
                        stage_priority[s] <= i[$clog2(STAGE_WIDTH)-1:0];
                    end
                end
            end
            
            // Combine results - find highest priority stage
            priority_out <= 0;
            for (integer s = STAGES-1; s >= 0; s = s - 1) begin
                if (stage_valid[s])
                    priority_out <= {s[$clog2(STAGES)-1:0], 
                                    stage_priority[s]};
            end
        end
    end
endmodule