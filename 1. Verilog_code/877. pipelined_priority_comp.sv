module pipelined_priority_comp #(parameter WIDTH = 16, STAGES = 2)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out,
    output reg valid_out
);
    // Pipeline stages
    reg [WIDTH-1:0] stage_data [0:STAGES-1];
    reg [STAGES-1:0] stage_valid;
    
    integer s, i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (s = 0; s < STAGES; s = s + 1) begin
                stage_data[s] <= 0;
                stage_valid[s] <= 0;
            end
            priority_out <= 0;
            valid_out <= 0;
        end else begin
            // First stage receives input
            stage_data[0] <= data_in;
            stage_valid[0] <= |data_in;
            
            // Propagate through pipeline
            for (s = 1; s < STAGES; s = s + 1) begin
                stage_data[s] <= stage_data[s-1];
                stage_valid[s] <= stage_valid[s-1];
            end
            
            // Output stage determines priority
            valid_out <= stage_valid[STAGES-1];
            priority_out <= 0;
            for (i = WIDTH-1; i >= 0; i = i - 1)
                if (stage_data[STAGES-1][i]) 
                    priority_out <= i[$clog2(WIDTH)-1:0];
        end
    end
endmodule