//SystemVerilog
module elias_gamma (
    input            clk,       // Clock signal for sequential logic
    input            rst_n,     // Reset signal
    input            req_i,     // Request signal
    input     [15:0] value_i,   // Input value
    output reg [31:0] code_o,   // Output code
    output reg [5:0]  length_o, // Output length
    output reg        ack_o     // Acknowledge signal
);
    // Stage 1: MSB finding pipeline registers
    reg [4:0] N_stage1;
    reg [15:0] value_stage1;
    reg req_stage1, processing_stage1;
    
    // Stage 2: Code generation pipeline registers
    reg [4:0] N_stage2;
    reg [15:0] value_stage2;
    reg req_stage2, processing_stage2;
    
    // Output stage registers
    reg [31:0] code_temp;
    reg [5:0] length_temp;
    
    // Control signals
    reg processing;
    
    // Intermediate signals for MSB detection
    wire [4:0] N_msb;
    wire [7:0] val_first_stage;
    wire [3:0] val_second_stage;
    wire [1:0] val_third_stage;
    
    // Stage 1: MSB finding logic - optimized and pipelined
    assign val_first_stage = (value_i[15:8] != 0) ? value_i[15:8] : value_i[7:0];
    assign val_second_stage = (val_first_stage[7:4] != 0) ? val_first_stage[7:4] : val_first_stage[3:0];
    assign val_third_stage = (val_second_stage[3:2] != 0) ? val_second_stage[3:2] : val_second_stage[1:0];
    
    // Calculate N (MSB position) using combinational logic
    assign N_msb = ((value_i[15:8] != 0) ? 5'd8 : 5'd0) +
                   ((val_first_stage[7:4] != 0) ? 5'd4 : 5'd0) +
                   ((val_second_stage[3:2] != 0) ? 5'd2 : 5'd0) +
                   ((val_third_stage[1] != 0) ? 5'd1 : 5'd0) + 5'd1;
    
    // Stage 1 pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            N_stage1 <= 5'd0;
            value_stage1 <= 16'd0;
            req_stage1 <= 1'b0;
            processing_stage1 <= 1'b0;
        end else begin
            if (req_i || processing) begin
                N_stage1 <= N_msb;
                value_stage1 <= value_i;
                req_stage1 <= req_i;
                processing_stage1 <= processing;
            end else if (!processing) begin
                req_stage1 <= 1'b0;
                processing_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2 pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            N_stage2 <= 5'd0;
            value_stage2 <= 16'd0;
            req_stage2 <= 1'b0;
            processing_stage2 <= 1'b0;
        end else begin
            N_stage2 <= N_stage1;
            value_stage2 <= value_stage1;
            req_stage2 <= req_stage1;
            processing_stage2 <= processing_stage1;
        end
    end
    
    // Code generation logic - split into a separate pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_temp <= 32'd0;
            length_temp <= 6'd0;
        end else if (req_stage2 || processing_stage2) begin
            // Calculate code and length based on N_stage2
            code_temp <= gen_elias_code(value_stage2, N_stage2);
            length_temp <= (2 * N_stage2) - 6'd1;
        end
    end
    
    // Function to generate Elias gamma code - encapsulated as a function for clarity
    function [31:0] gen_elias_code;
        input [15:0] value;
        input [4:0] N;
        reg [31:0] code;
        integer i;
    begin
        code = 32'd0;
        
        for (i = 0; i < 32; i = i + 1) begin
            if (i < N-1)
                code[31-i] = 1'b0;
            else if (i == N-1)
                code[31-i] = 1'b1;
            else if (i < 2*N-1)
                code[31-i] = value[N-1-(i-N)];
        end
        
        gen_elias_code = code;
    end
    endfunction
    
    // Handshake control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_o <= 32'd0;
            length_o <= 6'd0;
            ack_o <= 1'b0;
            processing <= 1'b0;
        end else begin
            if (req_i && !ack_o && !processing) begin
                // Start processing new request
                processing <= 1'b1;
            end else if (processing_stage2 && !ack_o) begin
                // Output stage - after pipeline delay
                code_o <= code_temp;
                length_o <= length_temp;
                ack_o <= 1'b1;
            end else if (!req_i && ack_o) begin
                // End of handshake
                ack_o <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
endmodule