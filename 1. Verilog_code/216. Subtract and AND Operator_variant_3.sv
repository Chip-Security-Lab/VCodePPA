//SystemVerilog
module shift_xor_operator (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output wire ready_out,
    input wire [7:0] a,
    input wire [2:0] shift_amount,
    output wire valid_out,
    input wire ready_in,
    output wire [7:0] shifted_result,
    output wire [7:0] xor_result
);

    // Stage 1 registers - Input capture
    reg [7:0] a_stage1;
    reg [2:0] shift_amount_stage1;
    reg valid_stage1;

    // Stage 2 registers - Shift operation
    reg [7:0] a_stage2;
    reg [7:0] shifted_result_stage2;
    reg valid_stage2;

    // Stage 3 registers - XOR operation
    reg [7:0] shifted_result_stage3;
    reg [7:0] xor_result_stage3;
    reg valid_stage3;

    // Handshake signals
    wire handshake_in = valid_in && ready_out;
    wire handshake_out = valid_out && ready_in;
    
    // Control signal assignments
    assign ready_out = !valid_stage1 || (valid_stage1 && !valid_stage2) || 
                      (valid_stage3 && handshake_out);
    assign valid_out = valid_stage3;
    
    // Output assignments
    assign shifted_result = shifted_result_stage3;
    assign xor_result = xor_result_stage3;
    
    // Stage 1: Input capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 8'b0;
            shift_amount_stage1 <= 3'b0;
            valid_stage1 <= 1'b0;
        end else if (handshake_in) begin
            a_stage1 <= a;
            shift_amount_stage1 <= shift_amount;
            valid_stage1 <= 1'b1;
        end else if (valid_stage1 && !valid_stage2) begin
            valid_stage1 <= 1'b0;
        end else if (valid_stage3 && handshake_out) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Shift operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage2 <= 8'b0;
            shifted_result_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1 && !valid_stage2) begin
            a_stage2 <= a_stage1;
            shifted_result_stage2 <= a_stage1 >> shift_amount_stage1;
            valid_stage2 <= 1'b1;
        end else if (valid_stage2 && !valid_stage3) begin
            valid_stage2 <= 1'b0;
        end else if (valid_stage3 && handshake_out) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: XOR operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_result_stage3 <= 8'b0;
            xor_result_stage3 <= 8'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2 && !valid_stage3) begin
            shifted_result_stage3 <= shifted_result_stage2;
            xor_result_stage3 <= a_stage2 ^ shifted_result_stage2;
            valid_stage3 <= 1'b1;
        end else if (handshake_out) begin
            valid_stage3 <= 1'b0;
        end
    end
    
endmodule