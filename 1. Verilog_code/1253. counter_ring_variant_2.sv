//SystemVerilog
module counter_ring #(parameter DEPTH=4) (
    input clk, rst_n,
    input enable,
    output reg [DEPTH-1:0] ring,
    output valid_out
);

    // Pipeline stage registers
    reg [DEPTH-1:0] ring_stage1;
    reg [DEPTH-1:0] ring_stage2;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    
    // Stage 1: Shift operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring_stage1 <= {1'b1, {DEPTH-1{1'b0}}};
            valid_stage1 <= 1'b0;
        end
        else begin
            if (enable) begin
                ring_stage1 <= {ring[DEPTH-2:0], ring[DEPTH-1]};
                valid_stage1 <= 1'b1;
            end
            else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Final processing and output preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring_stage2 <= {DEPTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            ring_stage2 <= ring_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring <= {1'b1, {DEPTH-1{1'b0}}};
        end
        else if (valid_stage2) begin
            ring <= ring_stage2;
        end
    end
    
    // Output valid signal
    assign valid_out = valid_stage2;
    
endmodule