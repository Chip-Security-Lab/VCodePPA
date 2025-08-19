module cam_pipelined #(parameter WIDTH=8, DEPTH=256)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    output reg [$clog2(DEPTH)-1:0] match_addr,
    output reg match_valid,
    output reg ready
);
    // Memory array
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    
    // Pipeline stage 1: Comparison
    reg [DEPTH-1:0] stage1_hits;
    reg [WIDTH-1:0] stage1_data_in;
    reg stage1_valid;
    
    // Pipeline stage 2: Priority encoding
    reg [DEPTH-1:0] stage2_hits;
    reg [$clog2(DEPTH)-1:0] stage2_addr;
    reg stage2_valid;
    
    // Pipeline stage 3: Output formatting
    reg [$clog2(DEPTH)-1:0] stage3_addr;
    reg stage3_valid;
    
    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all entries
            for (integer i = 0; i < DEPTH; i = i + 1)
                entries[i] <= {WIDTH{1'b0}};
        end else if (write_en) begin
            entries[write_addr] <= write_data;
        end
    end
    
    // Stage 1: Parallel comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_hits <= {DEPTH{1'b0}};
            stage1_data_in <= {WIDTH{1'b0}};
            stage1_valid <= 1'b0;
        end else begin
            stage1_data_in <= data_in;
            stage1_valid <= 1'b1;
            
            // Parallel comparison
            for (integer i = 0; i < DEPTH; i = i + 1)
                stage1_hits[i] <= (entries[i] == data_in);
        end
    end
    
    // Stage 2: Priority encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_hits <= {DEPTH{1'b0}};
            stage2_addr <= {$clog2(DEPTH){1'b0}};
            stage2_valid <= 1'b0;
        end else begin
            stage2_hits <= stage1_hits;
            stage2_valid <= stage1_valid;
            
            // Priority encoding
            stage2_addr <= {$clog2(DEPTH){1'b0}};
            for (integer i = 0; i < DEPTH; i = i + 1)
                if (stage1_hits[i])
                    stage2_addr <= i[$clog2(DEPTH)-1:0];
        end
    end
    
    // Stage 3: Output formatting
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_addr <= {$clog2(DEPTH){1'b0}};
            stage3_valid <= 1'b0;
        end else begin
            stage3_addr <= stage2_addr;
            stage3_valid <= stage2_valid && |stage2_hits;
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_addr <= {$clog2(DEPTH){1'b0}};
            match_valid <= 1'b0;
            ready <= 1'b1;
        end else begin
            match_addr <= stage3_addr;
            match_valid <= stage3_valid;
            ready <= 1'b1;
        end
    end
endmodule