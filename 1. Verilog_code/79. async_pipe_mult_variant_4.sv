//SystemVerilog
module async_pipe_mult (
    input [7:0] in1, in2,
    output [15:0] out,
    input req,
    output reg ack,
    input clk,
    input rst_n
);

    // Pipeline stages
    reg [7:0] in1_stage1, in2_stage1;
    reg [7:0] in1_stage2, in2_stage2;
    reg [15:0] product_stage2;
    reg [15:0] out_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    reg ack_stage1, ack_stage2, ack_stage3;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in1_stage1 <= 8'h00;
            in2_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
            ack_stage1 <= 1'b0;
        end else begin
            if (req && !ack) begin
                in1_stage1 <= in1;
                in2_stage1 <= in2;
                valid_stage1 <= 1'b1;
                ack_stage1 <= 1'b0;
            end else if (ack_stage3) begin
                valid_stage1 <= 1'b0;
                ack_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Multiplication
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in1_stage2 <= 8'h00;
            in2_stage2 <= 8'h00;
            product_stage2 <= 16'h0000;
            valid_stage2 <= 1'b0;
            ack_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                in1_stage2 <= in1_stage1;
                in2_stage2 <= in2_stage1;
                product_stage2 <= in1_stage1 * in2_stage1;
                valid_stage2 <= 1'b1;
                ack_stage2 <= 1'b0;
            end else if (ack_stage3) begin
                valid_stage2 <= 1'b0;
                ack_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_stage3 <= 16'h0000;
            valid_stage3 <= 1'b0;
            ack_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                out_stage3 <= product_stage2;
                valid_stage3 <= 1'b1;
                ack_stage3 <= 1'b1;
            end else if (ack) begin
                valid_stage3 <= 1'b0;
                ack_stage3 <= 1'b0;
            end
        end
    end
    
    // Output and ack assignment
    assign out = out_stage3;
    assign ack = ack_stage3;

endmodule