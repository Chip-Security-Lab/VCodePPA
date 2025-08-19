//SystemVerilog
module multibit_shifter (
    input wire clk,
    input wire reset,
    input wire [1:0] data_in,
    output reg [1:0] data_out
);
    // Pipeline stages for shift register
    reg [1:0] stage1_data;
    reg [1:0] stage2_data;
    reg [1:0] stage3_data;
    
    // Pipeline valid signals
    reg stage1_valid, stage2_valid, stage3_valid;
    
    always @(posedge clk) begin
        if (reset) begin
            // Reset all pipeline stages
            stage1_data <= 2'b00;
            stage2_data <= 2'b00;
            stage3_data <= 2'b00;
            data_out <= 2'b00;
            
            // Reset valid signals
            stage1_valid <= 1'b0;
            stage2_valid <= 1'b0;
            stage3_valid <= 1'b0;
        end
        else begin
            // Pipeline Stage 1: Input capture
            stage1_data <= data_in;
            stage1_valid <= 1'b1;
            
            // Pipeline Stage 2: First shift
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;
            
            // Pipeline Stage 3: Second shift
            stage3_data <= stage2_data;
            stage3_valid <= stage2_valid;
            
            // Output stage
            if (stage3_valid) begin
                data_out <= stage3_data;
            end
        end
    end
endmodule