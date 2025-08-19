//SystemVerilog
// Top-level module
module differential_decoder (
    input  wire       clk,
    input  wire       reset_b,
    input  wire       diff_in,
    output reg        decoded_out,
    output wire       parity_error
);
    // Internal signals
    wire diff_in_stage1;
    wire prev_diff_in_stage1;
    wire valid_stage1;
    wire decoded_out_stage2;
    wire valid_stage2;
    wire parity_bit_stage2;
    wire [2:0] bit_counter_stage3;
    wire expected_parity_stage3;
    wire parity_bit_stage3;
    wire valid_stage3;
    
    // Instantiate input capture module
    input_capture_stage input_capture_inst (
        .clk(clk),
        .reset_b(reset_b),
        .diff_in(diff_in),
        .diff_in_stage1(diff_in_stage1),
        .prev_diff_in_stage1(prev_diff_in_stage1),
        .valid_stage1(valid_stage1)
    );
    
    // Instantiate decode and parity module
    decode_parity_stage decode_parity_inst (
        .clk(clk),
        .reset_b(reset_b),
        .diff_in_stage1(diff_in_stage1),
        .prev_diff_in_stage1(prev_diff_in_stage1),
        .valid_stage1(valid_stage1),
        .decoded_out_stage2(decoded_out_stage2),
        .valid_stage2(valid_stage2),
        .parity_bit_stage2(parity_bit_stage2)
    );
    
    // Instantiate error detection module
    error_detection_stage error_detection_inst (
        .clk(clk),
        .reset_b(reset_b),
        .valid_stage2(valid_stage2),
        .parity_bit_stage2(parity_bit_stage2),
        .bit_counter_stage3(bit_counter_stage3),
        .expected_parity_stage3(expected_parity_stage3),
        .parity_bit_stage3(parity_bit_stage3),
        .valid_stage3(valid_stage3)
    );
    
    // Output stage
    always @(posedge clk or negedge reset_b) begin
        if (!reset_b) begin
            decoded_out <= 1'b0;
        end else if (valid_stage2) begin
            decoded_out <= decoded_out_stage2;
        end
    end
    
    // Error detection output
    assign parity_error = valid_stage3 && (bit_counter_stage3 == 3'b000) ? 
                         (parity_bit_stage3 != expected_parity_stage3) : 1'b0;
                         
endmodule

// Input capture stage module
module input_capture_stage (
    input  wire       clk,
    input  wire       reset_b,
    input  wire       diff_in,
    output reg        diff_in_stage1,
    output reg        prev_diff_in_stage1,
    output reg        valid_stage1
);
    always @(posedge clk or negedge reset_b) begin
        if (!reset_b) begin
            prev_diff_in_stage1 <= 1'b0;
            diff_in_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            prev_diff_in_stage1 <= diff_in;
            diff_in_stage1 <= diff_in;
            valid_stage1 <= 1'b1;
        end
    end
endmodule

// Decode and parity stage module
module decode_parity_stage (
    input  wire       clk,
    input  wire       reset_b,
    input  wire       diff_in_stage1,
    input  wire       prev_diff_in_stage1,
    input  wire       valid_stage1,
    output reg        decoded_out_stage2,
    output reg        valid_stage2,
    output reg        parity_bit_stage2
);
    always @(posedge clk or negedge reset_b) begin
        if (!reset_b) begin
            decoded_out_stage2 <= 1'b0;
            parity_bit_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                decoded_out_stage2 <= diff_in_stage1 ^ prev_diff_in_stage1;
                parity_bit_stage2 <= parity_bit_stage2 ^ (diff_in_stage1 ^ prev_diff_in_stage1);
            end
        end
    end
endmodule

// Error detection stage module
module error_detection_stage (
    input  wire       clk,
    input  wire       reset_b,
    input  wire       valid_stage2,
    input  wire       parity_bit_stage2,
    output reg [2:0]  bit_counter_stage3,
    output reg        expected_parity_stage3,
    output reg        parity_bit_stage3,
    output reg        valid_stage3
);
    always @(posedge clk or negedge reset_b) begin
        if (!reset_b) begin
            bit_counter_stage3 <= 3'b000;
            expected_parity_stage3 <= 1'b0;
            parity_bit_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            parity_bit_stage3 <= parity_bit_stage2;
            
            if (valid_stage2) begin
                bit_counter_stage3 <= bit_counter_stage3 + 1'b1;
                
                if (bit_counter_stage3 == 3'b111)
                    expected_parity_stage3 <= ~expected_parity_stage3;
            end
        end
    end
endmodule