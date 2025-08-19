//SystemVerilog
module DA_mult (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [3:0] x,
    input [3:0] y,
    output reg [7:0] out
);

    // Stage 1: Partial Product Generation
    reg [3:0] pp0_stage1, pp1_stage1, pp2_stage1, pp3_stage1;
    reg valid_stage1;
    reg [3:0] x_stage1;
    reg [3:0] y_stage1;
    
    // Stage 2: Shift Operations
    reg [7:0] shifted_pp1_stage2, shifted_pp2_stage2, shifted_pp3_stage2;
    reg [3:0] pp0_stage2;
    reg valid_stage2;
    
    // Stage 3: First Addition
    reg [7:0] temp_sum1_stage3;
    reg valid_stage3;
    
    // Stage 4: Second Addition
    reg [7:0] temp_sum2_stage4;
    reg valid_stage4;
    
    // Stage 5: Final Addition and Output
    reg valid_stage5;
    reg req_reg;
    
    // Stage 1 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            req_reg <= 1'b0;
        end else begin
            req_reg <= req;
            valid_stage1 <= req && !req_reg;
            
            if (req && !req_reg) begin
                x_stage1 <= x;
                y_stage1 <= y;
                
                pp0_stage1 <= y[0] ? x : 4'b0000;
                pp1_stage1 <= y[1] ? x : 4'b0000;
                pp2_stage1 <= y[2] ? x : 4'b0000;
                pp3_stage1 <= y[3] ? x : 4'b0000;
            end
        end
    end
    
    // Stage 2 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                pp0_stage2 <= pp0_stage1;
                shifted_pp1_stage2 <= {pp1_stage1, 1'b0};
                shifted_pp2_stage2 <= {pp2_stage1, 2'b00};
                shifted_pp3_stage2 <= {pp3_stage1, 3'b000};
            end
        end
    end
    
    // Stage 3 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            
            if (valid_stage2) begin
                temp_sum1_stage3 <= {4'b0000, pp0_stage2} + shifted_pp1_stage2;
            end
        end
    end
    
    // Stage 4 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage4 <= 1'b0;
        end else begin
            valid_stage4 <= valid_stage3;
            
            if (valid_stage3) begin
                temp_sum2_stage4 <= temp_sum1_stage3 + shifted_pp2_stage2;
            end
        end
    end
    
    // Stage 5 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage5 <= 1'b0;
            ack <= 1'b0;
            out <= 8'b0;
        end else begin
            valid_stage5 <= valid_stage4;
            
            if (valid_stage4) begin
                out <= temp_sum2_stage4 + shifted_pp3_stage2;
                ack <= 1'b1;
            end else if (!req && req_reg) begin
                ack <= 1'b0;
            end
        end
    end
    
endmodule