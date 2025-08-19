//SystemVerilog
module or_gate_8input_8bit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d,
    input wire [7:0] e,
    input wire [7:0] f,
    input wire [7:0] g,
    input wire [7:0] h,
    output reg [7:0] y
);
    // Input buffers to improve timing on the input paths
    reg [7:0] a_buf, b_buf, c_buf, d_buf, e_buf, f_buf, g_buf, h_buf;
    
    // Stage 1 registers - First level OR operations with meaningful names
    reg [7:0] ab_result_stage1;
    reg [7:0] cd_result_stage1;
    reg [7:0] ef_result_stage1;
    reg [7:0] gh_result_stage1;
    
    // Stage 2 registers - Second level OR operations with meaningful names
    reg [7:0] abcd_result_stage2;
    reg [7:0] efgh_result_stage2;
    
    // Balanced pipeline structure - Input buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all input buffers
            a_buf <= 8'h00;
            b_buf <= 8'h00;
            c_buf <= 8'h00;
            d_buf <= 8'h00;
            e_buf <= 8'h00;
            f_buf <= 8'h00;
            g_buf <= 8'h00;
            h_buf <= 8'h00;
        end else begin
            // Buffer all inputs to improve timing
            a_buf <= a;
            b_buf <= b;
            c_buf <= c;
            d_buf <= d;
            e_buf <= e;
            f_buf <= f;
            g_buf <= g;
            h_buf <= h;
        end
    end
    
    // Pipeline stage 1: Perform first level OR operations with balanced paths
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_result_stage1 <= 8'h00;
            cd_result_stage1 <= 8'h00;
            ef_result_stage1 <= 8'h00;
            gh_result_stage1 <= 8'h00;
        end else begin
            // First level data path operations
            ab_result_stage1 <= a_buf | b_buf;
            cd_result_stage1 <= c_buf | d_buf;
            ef_result_stage1 <= e_buf | f_buf;
            gh_result_stage1 <= g_buf | h_buf;
        end
    end
    
    // Pipeline stage 2: Perform second level OR operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abcd_result_stage2 <= 8'h00;
            efgh_result_stage2 <= 8'h00;
        end else begin
            // Second level data path operations
            abcd_result_stage2 <= ab_result_stage1 | cd_result_stage1;
            efgh_result_stage2 <= ef_result_stage1 | gh_result_stage1;
        end
    end
    
    // Pipeline stage 3: Final OR operation and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 8'h00;
        end else begin
            // Final data path operation
            y <= abcd_result_stage2 | efgh_result_stage2;
        end
    end
endmodule