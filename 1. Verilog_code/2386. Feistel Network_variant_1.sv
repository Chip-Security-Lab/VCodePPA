//SystemVerilog
module feistel_network #(parameter HALF_WIDTH = 16) (
    input wire clk, rst_n, enable,
    input wire [HALF_WIDTH-1:0] left_in, right_in,
    input wire [HALF_WIDTH-1:0] round_key,
    input wire valid_in,
    output reg [HALF_WIDTH-1:0] left_out, right_out,
    output reg valid_out
);
    // Precompute round key XOR at input stage to reduce critical path
    wire [HALF_WIDTH-1:0] f_output_prec;
    assign f_output_prec = right_in ^ round_key;
    
    // Pipeline stage 1 registers
    reg [HALF_WIDTH-1:0] stage1_right;
    reg [HALF_WIDTH-1:0] stage1_f_output;
    reg [HALF_WIDTH-1:0] stage1_left;
    reg stage1_valid;
    
    // Pipeline stage 2 registers
    reg [HALF_WIDTH-1:0] stage2_right;
    reg [HALF_WIDTH-1:0] stage2_left;
    reg stage2_valid;
    
    // Pipeline stage 1 - balanced path with precomputed f_output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_right <= {HALF_WIDTH{1'b0}};
            stage1_f_output <= {HALF_WIDTH{1'b0}};
            stage1_left <= {HALF_WIDTH{1'b0}};
            stage1_valid <= 1'b0;
        end 
        else if (enable) begin
            stage1_right <= right_in;
            stage1_f_output <= f_output_prec;  // Use precomputed value
            stage1_left <= left_in;
            stage1_valid <= valid_in;
        end
    end
    
    // Prepare stage 2 XOR computation
    wire [HALF_WIDTH-1:0] stage2_right_next;
    assign stage2_right_next = stage1_left ^ stage1_f_output;
    
    // Pipeline stage 2 with balanced logic paths
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_right <= {HALF_WIDTH{1'b0}};
            stage2_left <= {HALF_WIDTH{1'b0}};
            stage2_valid <= 1'b0;
        end 
        else if (enable) begin
            stage2_right <= stage2_right_next;  // Use precomputed value
            stage2_left <= stage1_right;
            stage2_valid <= stage1_valid;
        end
    end
    
    // Output stage - register direct connections for better timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_out <= {HALF_WIDTH{1'b0}};
            right_out <= {HALF_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end 
        else if (enable) begin
            left_out <= stage2_left;
            right_out <= stage2_right;
            valid_out <= stage2_valid;
        end
    end
endmodule