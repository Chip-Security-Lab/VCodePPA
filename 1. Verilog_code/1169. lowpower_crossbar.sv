module lowpower_crossbar (
    input wire clk, rst_n,
    input wire [63:0] in_data,
    input wire [7:0] out_sel,
    input wire [3:0] in_valid,
    output reg [63:0] out_data
);
    // Clock gating signals
    wire [3:0] clk_en;
    
    // Enable clock only for outputs that have valid data
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_clk_en
            assign clk_en[g] = |in_valid;
        end
    endgenerate
    
    // Create output generation for each segment
    wire [15:0] output_segment[0:3];
    
    genvar j;
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_output
            // Default values
            reg [15:0] segment_value;
            
            always @(*) begin
                segment_value = 16'h0000;
                if (in_valid[0] && out_sel[1:0] == g) segment_value = in_data[15:0];
                if (in_valid[1] && out_sel[3:2] == g) segment_value = in_data[31:16];
                if (in_valid[2] && out_sel[5:4] == g) segment_value = in_data[47:32];
                if (in_valid[3] && out_sel[7:6] == g) segment_value = in_data[63:48];
            end
            
            assign output_segment[g] = segment_value;
        end
    endgenerate
    
    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 64'h0000_0000_0000_0000;
        end else begin
            if (clk_en[0]) out_data[15:0] <= output_segment[0];
            if (clk_en[1]) out_data[31:16] <= output_segment[1];
            if (clk_en[2]) out_data[47:32] <= output_segment[2];
            if (clk_en[3]) out_data[63:48] <= output_segment[3];
        end
    end
endmodule