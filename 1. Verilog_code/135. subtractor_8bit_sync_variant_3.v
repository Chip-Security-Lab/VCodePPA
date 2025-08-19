module subtractor_8bit_pipelined (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] diff
);

    // Pipeline stage 1 registers
    reg [7:0] a_stage1, b_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [7:0] diff_stage2;
    reg valid_stage2;
    
    // Combinational logic for subtraction
    wire [7:0] diff_wire = a_stage1 - b_stage1;
    
    // Pipeline stage 1
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_stage1 <= 8'b0;
            b_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            diff_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            diff_stage2 <= diff_wire;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            diff <= 8'b0;
        end else begin
            diff <= valid_stage2 ? diff_stage2 : 8'b0;
        end
    end

endmodule