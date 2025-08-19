//SystemVerilog
module async_hamming_decoder(
    input clk,
    input rst_n,
    input [11:0] encoded_in,
    input valid_in,
    output ready_out,
    output reg [7:0] data_out,
    output reg single_err,
    output reg double_err,
    output valid_out,
    input ready_in
);

    // Stage 1 signals
    reg [11:0] encoded_stage1;
    reg valid_stage1;
    wire [3:0] syndrome_stage1;
    wire parity_check_stage1;
    
    // Stage 2 signals  
    reg [3:0] syndrome_stage2;
    reg parity_check_stage2;
    reg valid_stage2;
    wire single_error_stage2;
    wire double_error_stage2;
    wire [7:0] decoded_data_stage2;
    
    // Stage 3 signals
    reg single_error_stage3;
    reg double_error_stage3;
    reg [7:0] decoded_data_stage3;
    reg valid_stage3;
    
    // Handshaking state
    reg busy;
    
    // Stage 1: Input registration and syndrome calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_stage1 <= 12'h0;
            valid_stage1 <= 1'b0;
        end else if (valid_in && ready_out) begin
            encoded_stage1 <= encoded_in;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 1 combinational logic
    assign syndrome_stage1[0] = encoded_stage1[0] ^ encoded_stage1[2] ^ encoded_stage1[4] ^ 
                               encoded_stage1[6] ^ encoded_stage1[8] ^ encoded_stage1[10];
    assign syndrome_stage1[1] = encoded_stage1[1] ^ encoded_stage1[2] ^ encoded_stage1[5] ^ 
                               encoded_stage1[6] ^ encoded_stage1[9] ^ encoded_stage1[10];
    assign syndrome_stage1[2] = encoded_stage1[3] ^ encoded_stage1[4] ^ encoded_stage1[5] ^ 
                               encoded_stage1[6];
    assign syndrome_stage1[3] = encoded_stage1[7] ^ encoded_stage1[8] ^ encoded_stage1[9] ^ 
                               encoded_stage1[10];
    assign parity_check_stage1 = ^encoded_stage1;
    
    // Stage 2: Error detection and data decoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome_stage2 <= 4'h0;
            parity_check_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            syndrome_stage2 <= syndrome_stage1;
            parity_check_stage2 <= parity_check_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 2 combinational logic
    assign single_error_stage2 = |syndrome_stage2 & ~parity_check_stage2;
    assign double_error_stage2 = |syndrome_stage2 & parity_check_stage2;
    assign decoded_data_stage2 = {encoded_stage1[10:7], encoded_stage1[6:4], encoded_stage1[2]};
    
    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            single_error_stage3 <= 1'b0;
            double_error_stage3 <= 1'b0;
            decoded_data_stage3 <= 8'h0;
            valid_stage3 <= 1'b0;
        end else begin
            single_error_stage3 <= single_error_stage2;
            double_error_stage3 <= double_error_stage2;
            decoded_data_stage3 <= decoded_data_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignment
    assign ready_out = !busy || (valid_out && ready_in);
    assign valid_out = valid_stage3;
    
    // Control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            data_out <= 8'h0;
            single_err <= 1'b0;
            double_err <= 1'b0;
        end else begin
            if (valid_stage3) begin
                data_out <= decoded_data_stage3;
                single_err <= single_error_stage3;
                double_err <= double_error_stage3;
            end
            if (valid_in && ready_out) begin
                busy <= 1'b1;
            end else if (valid_out && ready_in) begin
                busy <= 1'b0;
            end
        end
    end

endmodule