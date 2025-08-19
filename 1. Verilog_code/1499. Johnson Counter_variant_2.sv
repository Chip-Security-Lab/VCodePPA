//SystemVerilog
//IEEE 1364-2005 Verilog
module johnson_counter (
    input wire clk,
    input wire arst,
    input wire enable,
    output wire [3:0] count_out,
    output wire valid_out
);
    // Pipeline stage 1: Initial counter
    reg [3:0] count_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Intermediate result
    reg [3:0] count_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3: Final output
    reg [3:0] count_stage3;
    reg valid_stage3;
    
    // Clock buffer tree
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Buffer for high fanout count_stage3 signal
    reg [3:0] count_stage3_buf1;
    reg [3:0] count_stage3_buf2;
    
    // Buffer for bit 0 which has high fanout
    reg b0_buf1, b0_buf2;
    
    // Clock buffer assignments to reduce fanout
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    assign clk_buf3 = clk;
    
    // Stage 1: Input processing
    always @(posedge clk_buf1 or posedge arst) begin
        if (arst) begin
            count_stage1 <= 4'b0000;
            valid_stage1 <= 1'b0;
            b0_buf1 <= 1'b0;
        end else if (enable) begin
            count_stage1 <= {count_stage3_buf1[2:0], ~count_stage3_buf1[3]};
            valid_stage1 <= 1'b1;
            b0_buf1 <= ~count_stage3_buf1[3];
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Intermediate processing
    always @(posedge clk_buf2 or posedge arst) begin
        if (arst) begin
            count_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
            b0_buf2 <= 1'b0;
        end else begin
            count_stage2 <= count_stage1;
            valid_stage2 <= valid_stage1;
            b0_buf2 <= b0_buf1;
        end
    end
    
    // Stage 3: Output processing
    always @(posedge clk_buf3 or posedge arst) begin
        if (arst) begin
            count_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
        end else begin
            count_stage3 <= count_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Buffer registers for high fanout signals
    always @(posedge clk_buf1 or posedge arst) begin
        if (arst) begin
            count_stage3_buf1 <= 4'b0000;
        end else begin
            count_stage3_buf1 <= count_stage3;
        end
    end
    
    always @(posedge clk_buf2 or posedge arst) begin
        if (arst) begin
            count_stage3_buf2 <= 4'b0000;
        end else begin
            count_stage3_buf2 <= count_stage3;
        end
    end
    
    // Output assignments
    assign count_out = count_stage3_buf2;
    assign valid_out = valid_stage3;
endmodule