//SystemVerilog
module one_hot_ring_counter(
    input wire clk,
    input wire rst_n,
    input wire enable, // Enable signal to control pipeline operation
    output reg [3:0] one_hot,
    output reg valid_out // Output valid signal
);
    // Pipeline stage registers
    reg [3:0] one_hot_stage1;
    reg [3:0] one_hot_stage2;
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Calculate next one-hot value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_hot_stage1 <= 4'b0001;
            valid_stage1 <= 1'b0;
        end
        else begin
            case ({enable, (one_hot == 4'b0000)})
                2'b11: begin
                    one_hot_stage1 <= 4'b0001; // Recovery logic when enabled
                    valid_stage1 <= 1'b1;
                end
                2'b10: begin
                    one_hot_stage1 <= {one_hot[2:0], one_hot[3]}; // Rotation when enabled
                    valid_stage1 <= 1'b1;
                end
                default: begin
                    // Keep current value when not enabled
                    valid_stage1 <= 1'b0;
                end
            endcase
        end
    end
    
    // Stage 2: Additional processing stage (for pipeline demonstration)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_hot_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end
        else begin
            case (enable)
                1'b1: begin
                    one_hot_stage2 <= one_hot_stage1;
                    valid_stage2 <= valid_stage1;
                end
                default: begin
                    valid_stage2 <= 1'b0;
                end
            endcase
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_hot <= 4'b0001;
            valid_out <= 1'b0;
        end
        else begin
            case (enable)
                1'b1: begin
                    one_hot <= one_hot_stage2;
                    valid_out <= valid_stage2;
                end
                default: begin
                    valid_out <= 1'b0;
                end
            endcase
        end
    end
endmodule