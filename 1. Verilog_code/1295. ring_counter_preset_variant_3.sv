//SystemVerilog
module ring_counter_preset (
    input wire clk,
    input wire rst_n, // Added reset signal for pipeline control
    input wire load,
    input wire [3:0] preset_val,
    input wire valid_in,  // Input valid signal
    output wire valid_out, // Output valid signal
    output reg [3:0] out
);
    // Pipeline stage registers
    reg [3:0] stage1_data;
    reg [3:0] stage2_data;
    reg load_stage1, load_stage2;
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Input and preprocessing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 4'b0000;
            load_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
            load_stage1 <= load;
            stage1_data <= load ? preset_val : {out[0], out[3:1]};
        end
    end
    
    // Stage 2: Processing and preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= 4'b0000;
            load_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            load_stage2 <= load_stage1;
            stage2_data <= stage1_data;
        end
    end
    
    // Final stage: Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 4'b0000;
        end else if (valid_stage2) begin
            out <= stage2_data;
        end
    end
    
    // Output valid signal
    assign valid_out = valid_stage2;
    
endmodule