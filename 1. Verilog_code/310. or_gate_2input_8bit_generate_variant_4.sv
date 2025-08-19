//SystemVerilog
module or_gate_2input_8bit_generate (
    input wire clk,            // Clock signal
    input wire rst_n,          // Active low reset
    
    // Input interface A
    input wire [7:0] a,        // Data input A
    input wire a_valid,        // Valid signal for input A
    output wire a_ready,       // Ready signal for input A
    
    // Input interface B
    input wire [7:0] b,        // Data input B
    input wire b_valid,        // Valid signal for input B
    output wire b_ready,       // Ready signal for input B
    
    // Output interface
    output wire [7:0] y,       // Data output
    output wire y_valid,       // Valid signal for output
    input wire y_ready         // Ready signal for output
);
    // Internal registers for handshaking and pipeline
    reg [7:0] a_reg, b_reg;
    reg [7:0] result_reg;
    reg input_valid;
    reg output_valid;
    
    // Handshaking logic
    wire input_handshake = a_valid && b_valid && (y_ready || !output_valid);
    wire output_handshake = y_valid && y_ready;
    
    // Ready signals generation
    assign a_ready = y_ready || !output_valid;
    assign b_ready = y_ready || !output_valid;
    
    // Valid signal for output
    assign y_valid = output_valid;
    
    // Output data assignment
    assign y = result_reg;
    
    // Input capture logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'h0;
            b_reg <= 8'h0;
            input_valid <= 1'b0;
        end else if (input_handshake) begin
            a_reg <= a;
            b_reg <= b;
            input_valid <= 1'b1;
        end else if (output_handshake) begin
            input_valid <= 1'b0;
        end
    end
    
    // Output generation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 8'h0;
            output_valid <= 1'b0;
        end else if (input_valid && (y_ready || !output_valid)) begin
            // Low 4 bits OR operation
            result_reg[0] <= a_reg[0] | b_reg[0];
            result_reg[1] <= a_reg[1] | b_reg[1];
            result_reg[2] <= a_reg[2] | b_reg[2];
            result_reg[3] <= a_reg[3] | b_reg[3];
            
            // High 4 bits OR operation
            result_reg[4] <= a_reg[4] | b_reg[4];
            result_reg[5] <= a_reg[5] | b_reg[5];
            result_reg[6] <= a_reg[6] | b_reg[6];
            result_reg[7] <= a_reg[7] | b_reg[7];
            
            output_valid <= 1'b1;
        end else if (output_handshake) begin
            output_valid <= 1'b0;
        end
    end
endmodule