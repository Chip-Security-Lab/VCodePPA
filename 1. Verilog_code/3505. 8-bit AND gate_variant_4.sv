//SystemVerilog
// SystemVerilog
// 8-bit AND gate with pipelined datapath and fanout optimization
module and_gate_8 (
    input wire clk,             // Clock input
    input wire rst_n,           // Active-low reset
    input wire [7:0] a_in,      // 8-bit input A
    input wire [7:0] b_in,      // 8-bit input B
    output reg [7:0] y_out      // 8-bit registered output Y
);
    // Reset buffer registers to reduce fanout
    reg rst_n_buf1, rst_n_buf2, rst_n_buf3;
    
    // Stage 1: Input registers to improve timing at module boundary
    reg [7:0] a_stage1, b_stage1;
    
    // Stage 2: Operation registers - split operation for better timing
    reg [3:0] lower_result;
    reg [3:0] upper_result;
    
    // Reset buffer logic to reduce rst_n fanout
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_buf1 <= 1'b0;
            rst_n_buf2 <= 1'b0;
            rst_n_buf3 <= 1'b0;
        end else begin
            rst_n_buf1 <= 1'b1;
            rst_n_buf2 <= 1'b1;
            rst_n_buf3 <= 1'b1;
        end
    end
    
    // Input stage pipeline with dedicated reset buffer
    always @(posedge clk or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            a_stage1 <= 8'b0;
            b_stage1 <= 8'b0;
        end else begin
            a_stage1 <= a_in;
            b_stage1 <= b_in;
        end
    end
    
    // Computation stage with dedicated reset buffer
    always @(posedge clk or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            lower_result <= 4'b0;
            upper_result <= 4'b0;
        end else begin
            lower_result <= a_stage1[3:0] & b_stage1[3:0];
            upper_result <= a_stage1[7:4] & b_stage1[7:4];
        end
    end
    
    // Output stage with dedicated reset buffer
    always @(posedge clk or negedge rst_n_buf3) begin
        if (!rst_n_buf3) begin
            y_out <= 8'b0;
        end else begin
            y_out <= {upper_result, lower_result};
        end
    end
endmodule