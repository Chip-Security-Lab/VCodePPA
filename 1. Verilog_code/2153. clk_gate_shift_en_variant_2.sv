//SystemVerilog
module clk_gate_shift_en #(parameter DEPTH=3) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire in,
    input wire valid_in,
    output wire valid_out,
    output wire [DEPTH-1:0] out
);

    // Stage 1 - Input registers moved past initial combinational logic
    wire [DEPTH-1:0] stage1_data_pre;
    wire stage1_valid_pre;
    reg [DEPTH-1:0] stage1_data;
    reg stage1_valid;
    
    // Stage 2 pipeline registers
    reg [DEPTH-1:0] stage2_data;
    reg stage2_valid;
    
    // Stage 3 pipeline registers - Output stage
    reg [DEPTH-1:0] stage3_data;
    reg stage3_valid;
    
    // Pipeline stage control signals
    reg stage1_ready, stage2_ready, stage3_ready;
    
    // Combinational logic moved before first register
    assign stage1_data_pre = {stage1_data[DEPTH-2:0], in};
    assign stage1_valid_pre = valid_in && stage2_ready;
    
    // Retimed Stage 1 (registers moved forward)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= {DEPTH{1'b0}};
            stage1_valid <= 1'b0;
            stage1_ready <= 1'b1;
        end else if (en) begin
            if (valid_in && stage2_ready) begin
                // Registering pre-processed data
                stage1_data <= stage1_data_pre;
                stage1_valid <= stage1_valid_pre;
                stage1_ready <= 1'b0;
            end else if (!valid_in) begin
                stage1_valid <= 1'b0;
                stage1_ready <= 1'b1;
            end else if (stage2_ready) begin
                stage1_ready <= 1'b1;
            end
        end
    end
    
    // Stage 2 with balanced logic
    wire [DEPTH-1:0] stage2_data_pre;
    wire stage2_valid_pre;
    
    // Combinational logic moved before second register
    assign stage2_data_pre = stage1_data;
    assign stage2_valid_pre = stage1_valid && stage3_ready;
    
    // Retimed Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= {DEPTH{1'b0}};
            stage2_valid <= 1'b0;
            stage2_ready <= 1'b1;
        end else if (en) begin
            if (stage1_valid && stage3_ready) begin
                stage2_data <= stage2_data_pre;
                stage2_valid <= stage2_valid_pre;
                stage2_ready <= 1'b0;
            end else if (!stage1_valid) begin
                stage2_valid <= 1'b0;
                stage2_ready <= 1'b1;
            end else if (stage3_ready) begin
                stage2_ready <= 1'b1;
            end
        end
    end
    
    // Optimized stage 3 with improved logic sharing
    wire [DEPTH-1:0] stage3_data_pre;
    wire stage3_valid_pre;
    
    assign stage3_data_pre = stage2_data;
    assign stage3_valid_pre = stage2_valid;
    
    // Retimed Stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data <= {DEPTH{1'b0}};
            stage3_valid <= 1'b0;
            stage3_ready <= 1'b1;
        end else if (en) begin
            if (stage2_valid) begin
                stage3_data <= stage3_data_pre;
                stage3_valid <= stage3_valid_pre;
                stage3_ready <= 1'b0;
            end else begin
                stage3_valid <= 1'b0;
                stage3_ready <= 1'b1;
            end
        end
    end
    
    // More efficient pipeline flushing logic
    reg flush_pipeline;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flush_pipeline <= 1'b0;
        end else if (en) begin
            flush_pipeline <= 1'b0; // Default no flush
        end
    end
    
    // Output assignment - no change needed
    assign out = stage3_data;
    assign valid_out = stage3_valid;
    
    // Optimized handshaking logic
    always @(posedge clk or posedge valid_out) begin
        if (!rst_n) begin
            stage3_ready <= 1'b1;
        end else if (valid_out) begin
            stage3_ready <= 1'b1;  // Release stage 3 after output is consumed
        end
    end

endmodule