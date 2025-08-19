//SystemVerilog
module ITRC_PseudoRandom #(
    parameter WIDTH = 8,
    parameter SEED = 32'hA5A5A5A5
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    output reg [$clog2(WIDTH)-1:0] selected_int
);
    // Stage 1: LFSR and Mask Generation
    reg [31:0] lfsr_stage1;
    reg [WIDTH-1:0] masked_stage1;
    
    // Stage 2: Parallel Prefix Priority Encoding
    reg [WIDTH-1:0] masked_stage2;
    reg [WIDTH-1:0] prefix_propagate [0:WIDTH-1];
    reg [WIDTH-1:0] prefix_generate [0:WIDTH-1];
    reg [$clog2(WIDTH)-1:0] priority_encoded_stage2;
    
    // Stage 3: Final Selection
    reg [$clog2(WIDTH)-1:0] selected_int_stage3;
    
    // Stage 1: LFSR and Mask Generation
    always @(posedge clk) begin
        if (!rst_n) begin
            lfsr_stage1 <= SEED;
            masked_stage1 <= 0;
        end else begin
            lfsr_stage1 <= {lfsr_stage1[30:0], lfsr_stage1[31] ^ lfsr_stage1[20] ^ lfsr_stage1[28] ^ lfsr_stage1[3]};
            masked_stage1 <= int_src & lfsr_stage1[WIDTH-1:0];
        end
    end
    
    // Stage 2: Parallel Prefix Priority Encoding
    always @(posedge clk) begin
        if (!rst_n) begin
            masked_stage2 <= 0;
            priority_encoded_stage2 <= 0;
            for (integer i = 0; i < WIDTH; i = i + 1) begin
                prefix_propagate[i] <= 0;
                prefix_generate[i] <= 0;
            end
        end else begin
            masked_stage2 <= masked_stage1;
            
            // Initialize prefix arrays
            for (integer i = 0; i < WIDTH; i = i + 1) begin
                prefix_propagate[i] <= (i == 0) ? 1'b1 : 1'b0;
                prefix_generate[i] <= masked_stage1[i];
            end
            
            // Parallel prefix computation
            for (integer level = 0; level < $clog2(WIDTH); level = level + 1) begin
                for (integer i = 0; i < WIDTH; i = i + 1) begin
                    if (i >= (1 << level)) begin
                        prefix_propagate[i] <= prefix_propagate[i] & prefix_propagate[i - (1 << level)];
                        prefix_generate[i] <= prefix_generate[i] | (prefix_propagate[i] & prefix_generate[i - (1 << level)]);
                    end
                end
            end
            
            // Priority encoding using prefix results
            priority_encoded_stage2 <= 0;
            for (integer i = 0; i < WIDTH; i = i + 1) begin
                if (prefix_generate[i] && !prefix_generate[i-1]) begin
                    priority_encoded_stage2 <= i;
                end
            end
        end
    end
    
    // Stage 3: Final Selection
    always @(posedge clk) begin
        if (!rst_n) begin
            selected_int_stage3 <= 0;
        end else begin
            selected_int_stage3 <= priority_encoded_stage2;
        end
    end
    
    assign selected_int = selected_int_stage3;
endmodule