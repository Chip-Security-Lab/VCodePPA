//SystemVerilog
module multiplier_4bit_shift (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [3:0] a,
    input [3:0] b,
    output reg [7:0] product
);
    // Stage 1 registers
    reg [3:0] a_stage1;
    reg [3:0] b_stage1;
    reg req_stage1;
    reg [7:0] partial_sum1;
    
    // Stage 2 registers
    reg [3:0] a_stage2;
    reg [3:0] b_stage2;
    reg req_stage2;
    reg [7:0] partial_sum2;
    
    // Stage 3 registers
    reg [3:0] a_stage3;
    reg [3:0] b_stage3;
    reg req_stage3;
    reg [7:0] partial_sum3;
    
    // Stage 4 registers
    reg [3:0] a_stage4;
    reg [3:0] b_stage4;
    reg req_stage4;
    reg [7:0] result;
    reg ack_stage4;
    
    // Stage 1: Input capture and first partial sum
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 4'd0;
            b_stage1 <= 4'd0;
            req_stage1 <= 1'b0;
            partial_sum1 <= 8'd0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            req_stage1 <= req;
            if (req) begin
                partial_sum1 <= 8'd0;
                if (b[0]) partial_sum1 <= a;
            end
        end
    end
    
    // Stage 2: Second partial sum
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage2 <= 4'd0;
            b_stage2 <= 4'd0;
            req_stage2 <= 1'b0;
            partial_sum2 <= 8'd0;
        end else begin
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            req_stage2 <= req_stage1;
            if (req_stage1) begin
                partial_sum2 <= partial_sum1;
                if (b_stage1[1]) partial_sum2 <= partial_sum1 + (a_stage1 << 1);
            end
        end
    end
    
    // Stage 3: Third partial sum
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage3 <= 4'd0;
            b_stage3 <= 4'd0;
            req_stage3 <= 1'b0;
            partial_sum3 <= 8'd0;
        end else begin
            a_stage3 <= a_stage2;
            b_stage3 <= b_stage2;
            req_stage3 <= req_stage2;
            if (req_stage2) begin
                partial_sum3 <= partial_sum2;
                if (b_stage2[2]) partial_sum3 <= partial_sum2 + (a_stage2 << 2);
            end
        end
    end
    
    // Stage 4: Final sum and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage4 <= 4'd0;
            b_stage4 <= 4'd0;
            req_stage4 <= 1'b0;
            result <= 8'd0;
            ack_stage4 <= 1'b0;
        end else begin
            a_stage4 <= a_stage3;
            b_stage4 <= b_stage3;
            req_stage4 <= req_stage3;
            if (req_stage3) begin
                result <= partial_sum3;
                if (b_stage3[3]) result <= partial_sum3 + (a_stage3 << 3);
                ack_stage4 <= 1'b1;
            end else if (!req_stage3) begin
                ack_stage4 <= 1'b0;
            end
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (ack_stage4) begin
            product <= result;
            ack <= 1'b1;
        end else begin
            ack <= 1'b0;
        end
    end
endmodule