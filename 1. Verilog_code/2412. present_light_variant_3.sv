//SystemVerilog
/* IEEE 1364-2005 Verilog */
module present_light (
    input wire clk,
    input wire rst_n,
    input wire enc_dec,
    input wire valid_in,
    input wire [63:0] plaintext,
    output reg [63:0] ciphertext,
    output reg valid_out
);
    // Intermediate combinational logic signals
    wire [63:0] xor_result;
    wire [79:0] rotated_key;
    
    // Optimized pipeline registers after moving forward through combinational logic
    reg [63:0] data_stage2;
    reg [79:0] key_reg_stage1, key_reg_stage2, key_reg_stage3;
    reg valid_stage1, valid_stage2;
    
    // Combinational logic moved before registers
    assign rotated_key = {key_reg_stage3[18:0], key_reg_stage3[79:19]};
    assign xor_result = plaintext ^ key_reg_stage1[63:0];
    
    // Pipeline stage 1: Moved register after key rotation
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            key_reg_stage1 <= 80'h0;
            valid_stage1 <= 1'b0;
        end else begin
            if (valid_in) begin
                key_reg_stage1 <= rotated_key;
                valid_stage1 <= valid_in;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 2: Moved register after XOR operation
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_stage2 <= 64'h0;
            key_reg_stage2 <= 80'h0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                data_stage2 <= xor_result;
                key_reg_stage2 <= key_reg_stage1;
                valid_stage2 <= valid_stage1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 3: Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            ciphertext <= 64'h0;
            key_reg_stage3 <= 80'h0;
            valid_out <= 1'b0;
        end else begin
            if (valid_stage2) begin
                ciphertext <= data_stage2;
                key_reg_stage3 <= key_reg_stage2;
                valid_out <= valid_stage2;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule