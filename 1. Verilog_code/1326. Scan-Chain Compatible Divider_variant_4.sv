//SystemVerilog
module scan_divider (
    input logic clk, rst_n, scan_en, scan_in,
    output logic clk_div,
    output logic scan_out
);
    // Stage 1: Counter management
    logic [2:0] counter_stage1;
    logic [2:0] next_counter;
    logic update_counter;
    logic reset_counter;
    logic stage1_valid;
    
    // Stage 2: Clock division logic
    logic [2:0] counter_stage2;
    logic update_clk_div;
    logic stage2_valid;
    
    // Calculate next counter value in stage 1
    always_comb begin
        update_counter = 1'b0;
        reset_counter = 1'b0;
        next_counter = counter_stage1;
        
        if (scan_en) begin
            next_counter = {counter_stage1[1:0], scan_in};
            update_counter = 1'b1;
        end else if (counter_stage1 == 3'd7) begin
            reset_counter = 1'b1;
            next_counter = 3'b000;
        end else begin
            next_counter = counter_stage1 + 3'd1;
            update_counter = 1'b1;
        end
    end
    
    // Stage 1 sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= 3'b000;
            stage1_valid <= 1'b0;
        end else begin
            if (update_counter || reset_counter) begin
                counter_stage1 <= next_counter;
                stage1_valid <= 1'b1;
            end else begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // Pipeline register between stage 1 and 2
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= 3'b000;
            stage2_valid <= 1'b0;
            update_clk_div <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            stage2_valid <= stage1_valid;
            update_clk_div <= reset_counter;
        end
    end
    
    // Stage 2: Clock division operation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 1'b0;
        end else if (stage2_valid && update_clk_div) begin
            clk_div <= ~clk_div;
        end
    end
    
    // Output stage
    assign scan_out = counter_stage2[2];
endmodule