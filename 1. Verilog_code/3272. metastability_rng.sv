module metastability_rng (
    input wire clk_sys,
    input wire rst_n,
    input wire meta_clk,
    output reg [7:0] random_value
);
    reg meta_stage1, meta_stage2;
    
    // Metastable input using clock domain crossing
    always @(posedge meta_clk or negedge rst_n) begin
        if (!rst_n)
            meta_stage1 <= 1'b0;
        else
            meta_stage1 <= ~meta_stage1;
    end
    
    // Capture metastable signal
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            meta_stage2 <= 1'b0;
        else 
            meta_stage2 <= meta_stage1;
    end
    
    // Generate random value
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            random_value <= 8'h42;
        else
            random_value <= {random_value[6:0], meta_stage2 ^ random_value[7]};
    end
endmodule