//SystemVerilog
module delta_encoder #(
    parameter WIDTH = 12
)(
    input                   clk_i,
    input                   en_i,
    input                   rst_i,
    input      [WIDTH-1:0]  data_i,
    output reg [WIDTH-1:0]  delta_o,
    output reg              valid_o
);
    // Stage 1 signals
    reg [WIDTH-1:0] prev_sample;
    reg [WIDTH-1:0] data_stage1;
    reg             valid_stage1;
    
    // Buffered high-fanout signals
    reg [WIDTH-1:0] data_stage1_buf1, data_stage1_buf2;
    reg [WIDTH-1:0] inverted_prev_buf1, inverted_prev_buf2;
    reg [WIDTH:0]   carry_buf1, carry_buf2;
    
    // Stage 2 signals
    reg [WIDTH-1:0] delta_stage2;
    reg             valid_stage2;
    
    // Conditional sum subtractor signals
    wire [WIDTH-1:0] inverted_prev;
    wire [WIDTH:0]   carry;
    wire [WIDTH-1:0] subtraction_result;
    
    // Stage 1: Input capture
    always @(posedge clk_i) begin
        if (rst_i) begin
            prev_sample <= 0;
            data_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (en_i) begin
            data_stage1 <= data_i;
            prev_sample <= data_i;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Buffer registers for high-fanout signals
    always @(posedge clk_i) begin
        if (rst_i) begin
            data_stage1_buf1 <= 0;
            data_stage1_buf2 <= 0;
            inverted_prev_buf1 <= 0;
            inverted_prev_buf2 <= 0;
            carry_buf1 <= 0;
            carry_buf2 <= 0;
        end else begin
            // Buffer data_stage1 signal
            data_stage1_buf1 <= data_stage1;
            data_stage1_buf2 <= data_stage1;
            
            // Buffer inverted_prev signal
            inverted_prev_buf1 <= ~prev_sample;
            inverted_prev_buf2 <= ~prev_sample;
            
            // Buffer initial carry
            carry_buf1[0] <= 1'b1;
            carry_buf2[0] <= 1'b1;
        end
    end
    
    // Conditional sum subtractor implementation
    assign inverted_prev = inverted_prev_buf1; // Use buffered signal
    assign carry[0] = carry_buf1[0];          // Use buffered initial carry
    
    // Split subtractor into two balanced groups to reduce critical path
    genvar i;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : gen_subtractor_lower
            assign subtraction_result[i] = data_stage1_buf1[i] ^ inverted_prev_buf1[i] ^ carry[i];
            assign carry[i+1] = (data_stage1_buf1[i] & inverted_prev_buf1[i]) | 
                               (data_stage1_buf1[i] & carry[i]) | 
                               (inverted_prev_buf1[i] & carry[i]);
                               
            // Buffer intermediate carry signals
            always @(posedge clk_i) begin
                if (rst_i)
                    carry_buf1[i+1] <= 0;
                else
                    carry_buf1[i+1] <= carry[i+1];
            end
        end
        
        for (i = WIDTH/2; i < WIDTH; i = i + 1) begin : gen_subtractor_upper
            assign subtraction_result[i] = data_stage1_buf2[i] ^ inverted_prev_buf2[i] ^ carry[i];
            assign carry[i+1] = (data_stage1_buf2[i] & inverted_prev_buf2[i]) | 
                               (data_stage1_buf2[i] & carry[i]) | 
                               (inverted_prev_buf2[i] & carry[i]);
                               
            // Buffer intermediate carry signals
            always @(posedge clk_i) begin
                if (rst_i)
                    carry_buf2[i+1] <= 0;
                else
                    carry_buf2[i+1] <= carry[i+1];
            end
        end
    endgenerate
    
    // Stage 2: Delta calculation using conditional sum subtractor
    always @(posedge clk_i) begin
        if (rst_i) begin
            delta_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            delta_stage2 <= subtraction_result;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk_i) begin
        if (rst_i) begin
            delta_o <= 0;
            valid_o <= 0;
        end else begin
            delta_o <= delta_stage2;
            valid_o <= valid_stage2;
        end
    end
endmodule