//SystemVerilog
module xor_stream_cipher #(parameter KEY_WIDTH = 8, DATA_WIDTH = 16) (
    input wire clk, rst_n,
    input wire [KEY_WIDTH-1:0] key,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire valid_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);
    // First stage - key transformation directly on input (no initial key registration)
    wire [KEY_WIDTH-1:0] key_shift = {key[0], key[KEY_WIDTH-1:1]};
    wire [KEY_WIDTH-1:0] key_next = key ^ key_shift;
    
    // Stage 1 registers - store transformed key instead of raw input
    reg [KEY_WIDTH-1:0] key_reg_stage1;
    reg [DATA_WIDTH-1:0] data_in_reg_stage1;
    reg valid_in_reg_stage1;
    
    // Stage 2 registers
    reg [KEY_WIDTH-1:0] key_reg_stage2;
    reg [DATA_WIDTH-1:0] data_in_reg_stage2;
    reg valid_in_reg_stage2;
    
    // Stage 3 registers
    reg [KEY_WIDTH-1:0] key_reg_stage3;
    reg [DATA_WIDTH-1:0] data_in_reg_stage3;
    reg valid_in_reg_stage3;
    
    // Pipeline stage 1: Register the transformed key
    always @(posedge clk) begin
        if (!rst_n) begin
            key_reg_stage1 <= {KEY_WIDTH{1'b0}};
            data_in_reg_stage1 <= {DATA_WIDTH{1'b0}};
            valid_in_reg_stage1 <= 1'b0;
        end else begin
            data_in_reg_stage1 <= data_in;
            valid_in_reg_stage1 <= valid_in;
            
            if (valid_in) begin
                key_reg_stage1 <= key_next; // Store transformed key directly
            end
        end
    end
    
    // Pipeline stage 2: Pass through
    always @(posedge clk) begin
        if (!rst_n) begin
            key_reg_stage2 <= {KEY_WIDTH{1'b0}};
            data_in_reg_stage2 <= {DATA_WIDTH{1'b0}};
            valid_in_reg_stage2 <= 1'b0;
        end else begin
            data_in_reg_stage2 <= data_in_reg_stage1;
            valid_in_reg_stage2 <= valid_in_reg_stage1;
            key_reg_stage2 <= key_reg_stage1;
        end
    end
    
    // Pipeline stage 3: Final preparation
    always @(posedge clk) begin
        if (!rst_n) begin
            key_reg_stage3 <= {KEY_WIDTH{1'b0}};
            data_in_reg_stage3 <= {DATA_WIDTH{1'b0}};
            valid_in_reg_stage3 <= 1'b0;
        end else begin
            data_in_reg_stage3 <= data_in_reg_stage2;
            valid_in_reg_stage3 <= valid_in_reg_stage2;
            key_reg_stage3 <= key_reg_stage2;
        end
    end
    
    // Output stage: XOR operation and output registration
    always @(posedge clk) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (valid_in_reg_stage3) begin
                data_out <= data_in_reg_stage3 ^ {DATA_WIDTH/KEY_WIDTH{key_reg_stage3}};
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule