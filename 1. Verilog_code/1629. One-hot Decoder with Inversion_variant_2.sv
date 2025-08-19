//SystemVerilog
module invert_decoder #(
    parameter INVERT_OUTPUT = 0
)(
    input wire clk,                    // Clock input
    input wire rst_n,                  // Active low reset
    input wire [2:0] bin_addr,         // Binary address input
    output reg [7:0] dec_out           // Decoded output
);

    // Internal signals with clear naming for data flow stages
    reg [7:0] decode_stage1;           // First decode stage
    reg [7:0] decode_stage2;           // Second decode stage (optional inversion)
    reg [7:0] decode_stage3;           // Additional pipeline stage
    
    // Optimized single-stage decode with direct shift operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_stage1 <= 8'b0;
        end else begin
            decode_stage1 <= (8'b00000001 << bin_addr);
        end
    end
    
    // Combined decode and inversion stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_stage2 <= 8'b0;
        end else begin
            decode_stage2 <= INVERT_OUTPUT ? ~decode_stage1 : decode_stage1;
        end
    end
    
    // Additional pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_stage3 <= 8'b0;
        end else begin
            decode_stage3 <= decode_stage2;
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dec_out <= 8'b0;
        end else begin
            dec_out <= decode_stage3;
        end
    end

endmodule