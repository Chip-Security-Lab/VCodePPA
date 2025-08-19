//SystemVerilog
module preset_ring_counter(
    input wire clk,
    input wire rst,
    input wire preset,
    output wire [3:0] q
);
    // Pipeline stage 1 - Input registration and control
    reg [3:0] q_stage1;
    reg preset_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 - Ring rotation logic
    reg [3:0] q_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 - Output registration
    reg [3:0] q_stage3;
    reg valid_stage3;
    
    // Stage 1: Input registration
    always @(posedge clk) begin
        if (rst) begin
            q_stage1 <= 4'b0001;
            preset_stage1 <= 1'b0;
            valid_stage1 <= 1'b1;
        end
        else begin
            preset_stage1 <= preset;
            valid_stage1 <= 1'b1;
            
            if (preset_stage1)
                q_stage1 <= 4'b1000;
            else if (valid_stage3)
                q_stage1 <= q_stage3;
        end
    end
    
    // Stage 2: Perform ring rotation computation
    always @(posedge clk) begin
        if (rst) begin
            q_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                if (preset_stage1)
                    q_stage2 <= 4'b1000;
                else
                    q_stage2 <= {q_stage1[2:0], q_stage1[3]};
            end
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk) begin
        if (rst) begin
            q_stage3 <= 4'b0001;
            valid_stage3 <= 1'b0;
        end
        else begin
            valid_stage3 <= valid_stage2;
            
            if (valid_stage2)
                q_stage3 <= q_stage2;
        end
    end
    
    // Output assignment
    assign q = q_stage3;
    
endmodule