//SystemVerilog
module dual_edge_divider (
    input wire clkin,
    input wire rst,
    output reg clkout
);
    // Pipeline stage registers for positive edge path
    reg [1:0] pos_count_stage1;
    reg [1:0] pos_count_stage2;
    reg pos_toggle_stage1;
    reg pos_toggle_stage2;
    reg pos_toggle_stage3;
    reg pos_count_max_stage1;
    reg pos_count_max_stage2;
    
    // Pipeline stage registers for negative edge path
    reg [1:0] neg_count_stage1;
    reg [1:0] neg_count_stage2;
    reg neg_toggle_stage1;
    reg neg_toggle_stage2;
    reg neg_toggle_stage3;
    reg neg_count_max_stage1;
    reg neg_count_max_stage2;
    
    // Pipeline valid signals
    reg pos_valid_stage1, pos_valid_stage2, pos_valid_stage3;
    reg neg_valid_stage1, neg_valid_stage2, neg_valid_stage3;
    
    // Stage 1: Counter and comparison logic (positive edge)
    always @(posedge clkin or posedge rst) begin
        if (rst) begin
            pos_count_stage1 <= 2'b00;
            pos_count_max_stage1 <= 1'b0;
            pos_valid_stage1 <= 1'b0;
        end else begin
            pos_count_max_stage1 <= (pos_count_stage1 == 2'b11);
            
            if (pos_count_stage1 == 2'b11)
                pos_count_stage1 <= 2'b00;
            else
                pos_count_stage1 <= pos_count_stage1 + 1'b1;
                
            pos_valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 1: Counter and comparison logic (negative edge)
    always @(negedge clkin or posedge rst) begin
        if (rst) begin
            neg_count_stage1 <= 2'b00;
            neg_count_max_stage1 <= 1'b0;
            neg_valid_stage1 <= 1'b0;
        end else begin
            neg_count_max_stage1 <= (neg_count_stage1 == 2'b11);
            
            if (neg_count_stage1 == 2'b11)
                neg_count_stage1 <= 2'b00;
            else
                neg_count_stage1 <= neg_count_stage1 + 1'b1;
                
            neg_valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Toggle control (positive edge)
    always @(posedge clkin or posedge rst) begin
        if (rst) begin
            pos_count_stage2 <= 2'b00;
            pos_count_max_stage2 <= 1'b0;
            pos_toggle_stage1 <= 1'b0;
            pos_valid_stage2 <= 1'b0;
        end else begin
            pos_count_stage2 <= pos_count_stage1;
            pos_count_max_stage2 <= pos_count_max_stage1;
            
            if (pos_valid_stage1) begin
                if (pos_count_max_stage1)
                    pos_toggle_stage1 <= ~pos_toggle_stage1;
                pos_valid_stage2 <= pos_valid_stage1;
            end
        end
    end
    
    // Stage 2: Toggle control (negative edge)
    always @(negedge clkin or posedge rst) begin
        if (rst) begin
            neg_count_stage2 <= 2'b00;
            neg_count_max_stage2 <= 1'b0;
            neg_toggle_stage1 <= 1'b0;
            neg_valid_stage2 <= 1'b0;
        end else begin
            neg_count_stage2 <= neg_count_stage1;
            neg_count_max_stage2 <= neg_count_max_stage1;
            
            if (neg_valid_stage1) begin
                if (neg_count_max_stage1)
                    neg_toggle_stage1 <= ~neg_toggle_stage1;
                neg_valid_stage2 <= neg_valid_stage1;
            end
        end
    end
    
    // Stage 3: Toggle buffer and synchronization (positive edge)
    always @(posedge clkin or posedge rst) begin
        if (rst) begin
            pos_toggle_stage2 <= 1'b0;
            pos_toggle_stage3 <= 1'b0;
            pos_valid_stage3 <= 1'b0;
        end else begin
            pos_toggle_stage2 <= pos_toggle_stage1;
            pos_toggle_stage3 <= pos_toggle_stage2;
            pos_valid_stage3 <= pos_valid_stage2;
        end
    end
    
    // Stage 3: Toggle buffer and synchronization (negative edge)
    always @(negedge clkin or posedge rst) begin
        if (rst) begin
            neg_toggle_stage2 <= 1'b0;
            neg_toggle_stage3 <= 1'b0;
            neg_valid_stage3 <= 1'b0;
        end else begin
            neg_toggle_stage2 <= neg_toggle_stage1;
            neg_toggle_stage3 <= neg_toggle_stage2;
            neg_valid_stage3 <= neg_valid_stage2;
        end
    end
    
    // Output generation with pipeline delay compensation
    always @(pos_toggle_stage3 or neg_toggle_stage3) begin
        if (pos_valid_stage3 && neg_valid_stage3)
            clkout = pos_toggle_stage3 ^ neg_toggle_stage3;
        else
            clkout = 1'b0;
    end
endmodule