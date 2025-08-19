//SystemVerilog
module binary_freq_div #(parameter WIDTH = 4) (
    input wire clk_in,
    input wire rst_n,
    output wire clk_out
);
    // Pipeline stage registers
    reg [WIDTH-1:0] count_r;
    reg [WIDTH-1:0] count_stage1_r;
    reg [WIDTH-1:0] count_stage2_r;
    
    // Pipeline valid signals
    reg valid_stage1_r;
    reg valid_stage2_r;
    
    // Pipeline output signals
    reg clk_out_stage1_r;
    reg clk_out_stage2_r;
    
    // Pipeline stage 1: Counter increment and MSB calculation
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            count_r <= {WIDTH{1'b0}};
            count_stage1_r <= {WIDTH{1'b0}};
            clk_out_stage1_r <= 1'b0;
            valid_stage1_r <= 1'b0;
        end
        else begin
            // Main counter
            count_r <= count_r + 1'b1;
            
            // Pass to stage 1
            count_stage1_r <= count_r;
            clk_out_stage1_r <= count_r[WIDTH-1];
            valid_stage1_r <= 1'b1;
        end
    end
    
    // Pipeline stage 2: Result propagation
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            count_stage2_r <= {WIDTH{1'b0}};
            clk_out_stage2_r <= 1'b0;
            valid_stage2_r <= 1'b0;
        end
        else begin
            count_stage2_r <= count_stage1_r;
            clk_out_stage2_r <= clk_out_stage1_r;
            valid_stage2_r <= valid_stage1_r;
        end
    end
    
    // Output assignment with pipeline valid qualification
    assign clk_out = valid_stage2_r ? clk_out_stage2_r : 1'b0;
endmodule